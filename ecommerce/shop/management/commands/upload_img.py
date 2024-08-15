from django.core.management.base import BaseCommand, CommandError
from django.core.files.storage import default_storage
from django.core.files.base import ContentFile
import os
from PIL import Image

class Command(BaseCommand):
    help = 'This is a custom command to upload demo files to Azure storage'

    def add_arguments(self, parser):
        # Add custom arguments here if needed
        pass 

    def handle(self, *args, **options):        
        img_dir = 'data/images'
        img_list = os.listdir(img_dir)

        for img in img_list:
            img_path = img_dir + '/' + img

            with open(img_path, mode='rb') as f:
                file_name = default_storage.save(img, ContentFile(f.read()))
                file_url = default_storage.url(file_name)

            self.stdout.write(file_url)

        
        # Raise a CommandError to signal something went wrong
        # raise CommandError('An error occurred')
