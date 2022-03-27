from django.urls import path

from . import views


app_name = 'api'
urlpatterns = [
    path('', views.api_root),
    path('results/', views.ResultList.as_view(), name='result-list'),
    path('results/<int:pk>/', views.ResultDetail.as_view()),
    path('users/', views.UserList.as_view(), name='user-list'),
    path('users/<int:pk>/', views.UserDetail.as_view()),
    path('load-image', views.LoadImageView.as_view(), name='load-image'),
    path('register', views.UserCreate.as_view(), name='register'),
    path('process-image', views.ProcessImageView.as_view(), name='process-image'),
    path('contact-us', views.SendContactUs.as_view(), name='contact-us'),
    path('get-progress', views.get_task_info, name='get-progress'),
]
