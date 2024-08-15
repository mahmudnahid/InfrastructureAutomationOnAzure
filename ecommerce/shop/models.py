from django.db import models
from django.contrib.auth.models import User
from django.conf import settings


class Product(models.Model):
    name = models.CharField(max_length=100)
    description = models.TextField(max_length=300)
    image = models.ImageField(upload_to='product', editable=True)
    price = models.DecimalField(max_digits=6,decimal_places=2)
    stock_quantity = models.IntegerField(default=0) 
    category = models.CharField(max_length=100)

    def __str__(self):
        return f"{self.name}"
    

class Rating(models.Model):
    product = models.OneToOneField(Product, related_name="rating", 
                                   on_delete=models.CASCADE, primary_key=True)
    rate = models.IntegerField(default=0)
    count = models.IntegerField(default=0)

    def __str__(self):
        return f"Rating: {self.rate}, Product: {self.product.name}"
    
    
class Cart(models.Model):
    user = models.OneToOneField(User, related_name="cart", on_delete=models.CASCADE, primary_key=True)
    
    def get_total_price(self):
        total = 0.0
        for item in self.items.all():
            total+= item.get_total_item_price()
        return round(total,2)
    
    def get_taxes(self):
        return round(0.18 * self.get_total_price(),2)
    
    def get_total(self):
        return round((self.get_total_price() + self.get_taxes()),2)



class CartItem(models.Model):
    cart = models.ForeignKey(Cart, related_name="items", on_delete=models.CASCADE)
    product = models.ForeignKey(Product, related_name="cart_items", on_delete=models.CASCADE)
    quantity = models.IntegerField(default=1)
    total_item_price = models.DecimalField(max_digits=6,decimal_places=2)

    def get_total_item_price(self):        
        return float(self.quantity * self.product.price)
    
    def save(self, *args, **kwargs) -> None:
        self.total_item_price = self.get_total_item_price()
        return super().save(*args, **kwargs)

    
class Order(models.Model):
    STATUS_CHOICES = [
        ("PR", "Processing"),
        ("DL", "Delivered")
    ]

    user = models.ForeignKey(User, related_name="orders", on_delete=models.CASCADE)
    shipping_name = models.CharField(max_length=100, null=True)
    shipping_address = models.TextField(max_length=300, null=True)
    phone = models.IntegerField(max_length=10, null=True)
    order_date = models.DateTimeField(auto_now_add=True)
    status = models.CharField(max_length=3, choices=STATUS_CHOICES, default="PR")
    total_price = models.DecimalField(max_digits=6,decimal_places=2)
    taxes = models.DecimalField(max_digits=6,decimal_places=2)
    total_amount = models.DecimalField(max_digits=6,decimal_places=2)

    def __str__(self):
        return f"User: {self.user.email}, Order: {self.id}"


class OrderItem(models.Model):
    order = models.ForeignKey(Order, related_name="items", on_delete=models.CASCADE)
    product = models.ForeignKey(Product, related_name="order_items", on_delete=models.CASCADE)
    quantity = models.IntegerField(default=1)
    total_item_price = models.DecimalField(max_digits=6,decimal_places=2)

    def get_total_item_price(self):        
        return float(self.quantity * self.product.price)
    
    def save(self, *args, **kwargs) -> None:
        self.total_item_price = self.get_total_item_price()
        return super().save(*args, **kwargs)



