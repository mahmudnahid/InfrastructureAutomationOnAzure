from django.shortcuts import render, redirect
from .models import Product, Rating, Cart, CartItem, Order,OrderItem
from django.core.exceptions import ObjectDoesNotExist
from django.contrib import messages
from django.contrib.auth.models import User, auth 
from shop import service_bus 
import json



def index(request):
    products = Product.objects.all()
    if request.user.is_authenticated:
        try:
            cart = Cart.objects.filter(user=request.user).first()
            if cart:
                cart_quantity=cart.items.count()
            else:
                cart_quantity = 0
            return render(request,"index.html",{'products':products,'cart':cart,'cart_quantity':cart_quantity})
        
        except:
            return render(request,"index.html",{'products':products})
    else:
        return render(request,"index.html",{'products':products})


def about(request):
    return render(request,"about.html")


def contacts(request):
    return render(request,"contacts.html")


def register(request):
    if request.method=='POST':
        username = request.POST['userName'].upper()
        first_name = request.POST['firstName'].upper()
        last_name = request.POST['lastName'].upper()
        email = request.POST['email'].upper()
        password = request.POST['password']
        password2 = request.POST['password-repeat']
        if(password==password2):
            if User.objects.filter(email=email).exists():
                messages.info(request,"Email taken")
                return redirect('register')
            elif User.objects.filter(username=username).exists():
                messages.info(request,"Username taken")
                return redirect('register')
            else:
                user = User.objects.create_user(email=email,username=username,first_name=first_name,last_name=last_name,password=password)
                user.save()
        else:
            messages.info(request,"password not matching")
            return redirect('register')
        return redirect('index')
    else:
        return render(request,"register.html")
    

def login(request):
    if request.method=='POST':
        username = request.POST['userName'].upper()
        password = request.POST['password']
        user = auth.authenticate(username=username,password=password)
        if user is not None:
            auth.login(request,user)
            return redirect('index')
        else:
            return redirect('login')
    else:
        return render(request,"login.html")
    
    
def logout(request):
    auth.logout(request)
    return redirect("index")

    
def shop_details(request, product_id):
    product = Product.objects.get(id=product_id)
    return render(request,"shop-details.html",{'product':product})


def cart(request):
    if request.user.is_authenticated:
        try:
            cart = Cart.objects.get(user=request.user)
            return render(request,"shopping-cart.html",{'cart':cart})
        except ObjectDoesNotExist:
            return redirect("index")
    else:
        return redirect("login")
       
      
def add_to_cart(request, product_id):
    if request.user.is_authenticated:
        try:
            product = Product.objects.filter(id=product_id).first() 
            # This is a trick to return None if object doesn't exist
            cart = Cart.objects.filter(user=request.user).first()

            if cart:
                cart_item = cart.items.filter(product=product).first()
                if cart_item:
                    cart_item.quantity+=1
                    cart_item.save()
                else:
                    cart_item = CartItem.objects.create(cart=cart, product=product, quantity=1)
            else:
                cart = Cart.objects.create(user=request.user)
                CartItem.objects.create(cart=cart, product=product, quantity=1)
            return redirect("cart")
        except:
            return redirect("login")
    else:
        return redirect("login")

    
def remove_from_cart(request, product_id):
    if request.user.is_authenticated:
        try:
            product = Product.objects.filter(id=product_id).first() 
            cart = Cart.objects.filter(user=request.user).first()

            if cart:
                cart_item = cart.items.filter(product=product).first()
                if cart_item:
                    cart_item.delete()

            return redirect("cart")
        
        except:
            return redirect("login")
    else:
        return redirect("login")


def remove_single_item(request, product_id):
    if request.user.is_authenticated:
        product = Product.objects.filter(id=product_id).first() 
        cart = Cart.objects.filter(user=request.user).first()

        if cart:
            cart_item = cart.items.filter(product=product).first()
            if cart_item:
                if cart_item.quantity>1:
                    cart_item.quantity-=1
                    cart_item.save()
                else:
                    cart_item.delete()

        return redirect("cart")
    
    else:
        return redirect("login")


def checkout(request):
    if request.user.is_authenticated:        
        cart = Cart.objects.filter(user=request.user).first()
        if cart:
            return render(request,"checkout.html", {'cart':cart})
        else:
            return render(request,"checkout.html")
    else:
        return redirect("login")



def process_order(request):
    if request.method=='POST':
        firstName = request.POST['firstName']
        lastName = request.POST['lastName']
        country = request.POST['country']
        state= request.POST['state']
        city = request.POST['city']
        streetAddress = request.POST['streetAddress']
        postCode = request.POST['postCode']
        email = request.POST['email']
        phone = request.POST['phone']

        shipping_name = f'{firstName} {lastName}'
        shipping_address = f'Street: {streetAddress}, City: {city}, Post Code: {postCode}, State: {state}, Country: {country}, Email: {email}'
        
        cart = Cart.objects.filter(user=request.user).first()

        if cart:
            order = Order.objects.create(
                user = request.user,
                shipping_name = shipping_name,
                shipping_address = shipping_address,
                phone = phone,
                total_price = cart.get_total_price(),
                taxes = cart.get_taxes(),
                total_amount = cart.get_total() 
            )

            order_items = [
            OrderItem(order=order, product=cart_item.product, quantity=cart_item.quantity, total_item_price=cart_item.total_item_price)
                for cart_item in cart.items.all()
            ]
            OrderItem.objects.bulk_create(order_items)
            # As we have created the order so we can remove the cart
            cart.delete()

            # Send Email to user
            bus_service = service_bus.AzureServiceBus()            
            message_content ={ "username": shipping_name, "price": order.total_amount, "email": email}
            json_msg = json.dumps(message_content)
            bus_service.send_message(json_msg)

            return redirect('order-summary', order_id=order.id)

    return redirect("cart")


def order_summary(request, order_id):
    if request.user.is_authenticated:
        order = Order.objects.filter(id=order_id).first()
        if order:
            return render(request,"order-summary.html", {'order':order})
        
    return redirect("cart")












    


    