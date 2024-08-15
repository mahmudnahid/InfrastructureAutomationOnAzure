
from django.contrib import admin
from django.urls import path
from . import views

urlpatterns = [
    path("", views.index, name="index"),
    path('about', views.about, name="about"),
    path('contacts', views.contacts, name="contacts"),
    path('register', views.register, name="register"),
    path('login', views.login, name="login"),
    path('logout', views.logout, name="logout"),
    path('shop-details/<int:product_id>', views.shop_details, name="shop-details"),
    path('cart', views.cart, name="cart"),
    path('add-to-cart/<int:product_id>', views.add_to_cart, name="add-to-cart"),
    path('remove-from-cart/<int:product_id>', views.remove_from_cart, name="remove-from-cart"),
    path('remove-one-from-cart/<int:product_id>', views.remove_single_item, name="remove-one-from-cart"),
    path('checkout', views.checkout, name="checkout"),
    path('process-order', views.process_order, name="process-order"),
    path('order-summary/<int:order_id>', views.order_summary, name="order-summary"),
]
