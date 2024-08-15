from django.core.management.base import BaseCommand, CommandError
import pandas as pd
from shop.models import Product, Rating

class Command(BaseCommand):
    help = 'This is a custom command to populate database with demo data'

    def add_arguments(self, parser):
        # Add custom arguments here if needed
        pass 

    def handle(self, *args, **options):
        data_exists = Product.objects.exists()
        if not data_exists:
            # Read Product Data
            product_file = 'data/product.csv'
            product_list = []
            product_df = pd.read_csv(product_file, sep=';', encoding='cp1252')
            product_df.drop('rating_id', axis=1, inplace=True)

            # Insert Products
            for index, row in product_df.iterrows():
                p = Product(name=row["title"],
                            description=row["description"],
                            image=row["image"],
                            price=row["price"],
                            stock_quantity=row["quantity"],
                            category=row["category"])
                p.save()
                product_list.append(p)
            
            # Read Rating Data
            rating_file = 'data/rating.csv'
            rating_df = pd.read_csv(rating_file, sep=';', encoding='cp1252')
            rating_df = rating_df[:20]
            rating_df["product"] = product_list

            # Insert Ratings
            for index, row in rating_df.iterrows():
                r = Rating(product=row["product"], rate=row["rate"], count=row["count"])
                r.save()

            self.stdout.write('Successfully loaded demo Data.')
        else:
            self.stdout.write('Data already exists!')


        # Raise a CommandError to signal something went wrong
        # raise CommandError('An error occurred')
