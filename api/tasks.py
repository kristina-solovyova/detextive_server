import string
import pandas as pd
import os.path

from django.contrib.auth.models import User
from django.utils.crypto import get_random_string
from pandas.api.types import is_string_dtype

from celery import shared_task
from .matlab_caller import process_image
from .models import TextPosition, Result


# TODO: Process image task class with func 'localize' & 'recognize'
@shared_task
def create_random_user_accounts(total):
    for i in range(total):
        username = 'user_{}'.format(get_random_string(10, string.ascii_letters))
        email = '{}@example.com'.format(username)
        password = 'superpassword'
        User.objects.create_user(username=username, email=email, password=password)
    return '{} random users created with success!'.format(total)


@shared_task
def process(image_url, image_id):
    process_image(image_url, str(image_id))
    file_name = '%s.csv' % str(image_id)

    if os.path.exists(file_name):
        df = pd.read_csv(file_name, sep=';')
        num_results = df.shape[0]

        if is_string_dtype(df.Word):
            text = df.Word.str.cat(sep='\n')
        else:
            text = ''

        result = Result.objects.get(image_id=image_id)
        result.text = text
        result.save()

        for i in range(num_results):
            tp = df.iloc[i]
            new_tp = TextPosition(result=result, x=tp.X, y=tp.Y, width=tp.W, height=tp.H, angle=float(tp.Angle))
            new_tp.save()

        os.remove(file_name)

    return 'Result: %s is processed' % image_url
