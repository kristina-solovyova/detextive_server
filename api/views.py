from celery.result import AsyncResult
from django.core.exceptions import ValidationError
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.parsers import FileUploadParser
from rest_framework import status
from rest_framework import permissions
from rest_framework import viewsets
from rest_framework import generics
from rest_framework.decorators import api_view
from rest_framework.reverse import reverse
from api.serializers import *
from .models import Result, Image
from .permissions import IsOwnerOrReadOnly
from .tasks import process


@api_view(['GET'])
def api_root(request, format=None):
    return Response({
        'users': reverse('api:user-list', request=request, format=format),
        'results': reverse('api:result-list', request=request, format=format)
    })


class LoadImageView(APIView):
    permission_classes = (permissions.IsAuthenticated, )
    parser_class = (FileUploadParser,)

    def post(self, request):
        image_serializer = ImageSerializer(data=request.data)

        if image_serializer.is_valid():
            image_serializer.save(user=request.user)
            return Response(image_serializer.data, status=status.HTTP_201_CREATED)
        else:
            return Response(image_serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# TODO: replace stub method with image process logic
class ProcessImageView(APIView):
    permission_classes = (permissions.IsAuthenticated, IsOwnerOrReadOnly)

    def post(self, request):
        if 'image_id' in request.data:
            image_id = request.data['image_id']
            image = Image.objects.get(pk=image_id)
            new_result = Result(user=request.user, image=image)

            task = process.delay(image.img.url, image_id)

            try:
                new_result.full_clean()
                new_result.save()
                return Response({'state': 'Processing', 'task_id': task.id, 'result_id': new_result.id},
                                status=status.HTTP_201_CREATED)
            except ValidationError as e:
                return Response(e.message_dict, status=status.HTTP_422_UNPROCESSABLE_ENTITY)

        return Response('No image_id param', status=status.HTTP_422_UNPROCESSABLE_ENTITY)


@api_view(['GET'])
def get_task_info(request):
    task_id = request.GET['task_id']
    if task_id is not None:
        task = AsyncResult(task_id)
        return Response({'state': task.state}, content_type='application/json')
    else:
        return Response('No job id given.')


class ResultList(generics.ListAPIView):
    permission_classes = (permissions.IsAuthenticated, IsOwnerOrReadOnly)
    serializer_class = ResultSerializer

    def get_queryset(self):
        return Result.objects.filter(user=self.request.user)

    # def perform_create(self, serializer):
    #     serializer.save(user=self.request.user)


class ResultDetail(generics.RetrieveDestroyAPIView):
    permission_classes = (permissions.IsAuthenticated, IsOwnerOrReadOnly)
    serializer_class = ResultDetailSerializer

    def get_queryset(self):
        return Result.objects.filter(user=self.request.user)


class UserCreate(generics.CreateAPIView):
    permission_classes = (permissions.AllowAny,)

    def create(self, request, *args, **kwargs):
        user_serializer = NewUserSerializer(data=request.data)
        if user_serializer.is_valid():
            user_serializer.save()  # TODO: do not display hashed password
            return Response(user_serializer.data, status=status.HTTP_201_CREATED)
        return Response(user_serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class UserList(generics.ListAPIView):
    queryset = User.objects.all().order_by('-date_joined')
    serializer_class = UserSerializer


class SendContactUs(generics.CreateAPIView):
    permission_classes = (permissions.AllowAny,)
    serializer_class = ContactUsSerializer


class UserDetail(generics.RetrieveAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer


class GroupViewSet(viewsets.ModelViewSet):
    queryset = Group.objects.all()
    serializer_class = GroupSerializer

