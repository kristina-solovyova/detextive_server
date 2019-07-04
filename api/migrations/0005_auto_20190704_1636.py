# Generated by Django 2.2.2 on 2019-07-04 13:36

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('api', '0004_textposition'),
    ]

    operations = [
        migrations.AlterField(
            model_name='result',
            name='datetime',
            field=models.DateTimeField(auto_now=True),
        ),
        migrations.AlterField(
            model_name='textposition',
            name='angle',
            field=models.DecimalField(decimal_places=2, max_digits=5),
        ),
    ]
