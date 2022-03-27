from django.contrib.auth.models import User, Group
from rest_framework import serializers
from rest_framework.validators import UniqueValidator
from .models import Result, Image, ContactUs, TextPosition


class ImageSerializer(serializers.ModelSerializer):
    user = serializers.ReadOnlyField(source='user.username')

    class Meta:
        model = Image
        fields = "__all__"


class ResultSerializer(serializers.ModelSerializer):
    user = serializers.ReadOnlyField(source='user.username')
    image_url = serializers.ReadOnlyField(source='image.img.url')

    class Meta:
        model = Result
        fields = ('id', 'image_url', 'datetime', 'text', 'user')


class TextPositionSerializer(serializers.ModelSerializer):
    result_id = serializers.ReadOnlyField(source='result.id')

    class Meta:
        model = TextPosition
        fields = "__all__"


class ResultDetailSerializer(serializers.ModelSerializer):
    user = serializers.ReadOnlyField(source='user.username')
    image_url = serializers.ReadOnlyField(source='image.img.url')
    text_positions = TextPositionSerializer(many=True, read_only=True)

    class Meta:
        model = Result
        fields = ('id', 'image_url', 'datetime', 'text', 'user', 'text_positions')


class NewUserSerializer(serializers.ModelSerializer):
    email = serializers.EmailField(required=True, validators=[UniqueValidator(queryset=User.objects.all())])
    username = serializers.CharField(validators=[UniqueValidator(queryset=User.objects.all())])
    password = serializers.CharField(min_length=8)

    def create(self, validated_data):
        user = User.objects.create_user(validated_data['username'], validated_data['email'], validated_data['password'])
        return user

    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'password')


class UserSerializer(serializers.ModelSerializer):
    results = serializers.PrimaryKeyRelatedField(many=True, queryset=Result.objects.all())

    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'date_joined', 'results')


class ContactUsSerializer(serializers.ModelSerializer):
    class Meta:
        model = ContactUs
        fields = "__all__"


class GroupSerializer(serializers.HyperlinkedModelSerializer):
    class Meta:
        model = Group
        fields = ('url', 'name')
