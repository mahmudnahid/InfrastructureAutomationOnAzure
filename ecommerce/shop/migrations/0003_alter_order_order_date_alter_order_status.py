# Generated by Django 5.0.7 on 2024-08-12 05:14

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('shop', '0002_alter_product_category_remove_order_address_and_more'),
    ]

    operations = [
        migrations.AlterField(
            model_name='order',
            name='order_date',
            field=models.DateTimeField(auto_now_add=True),
        ),
        migrations.AlterField(
            model_name='order',
            name='status',
            field=models.CharField(choices=[('PR', 'Processing'), ('DL', 'Delivered')], default='PR', max_length=3),
        ),
    ]
