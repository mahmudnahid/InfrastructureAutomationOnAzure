#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

# Initialize variables
MYSQL_HOST=$1
MYSQL_DB_NAME=$2
MYSQL_USER=$3
MYSQL_PASSWORD=$4
AZ_ACCOUNT_NAME=$5
AZ_ACCOUNT_KEY=$6
AZURE_SERVICE_BUS_QUEUE_NAME=$7
AZURE_SERVICE_BUS_CONNECTION_STRING=$8


sudo apt update && apt upgrade -y
sudo apt install pkg-config -y

# Install git
sudo apt install -y git

# Install mysqlclient-dev dependency
sudo apt install libmysqlclient-dev -y

# Install pip and venv
sudo apt -y install python3-pip
sudo apt install -y python3-venv

# Install nginx
sudo apt install -y nginx

# Install Supervisor
sudo apt install supervisor -y

# Clone project repository
cd /var/www/html
git clone https://github.com/WIP-2024/CloudNine.git

# For Debugging give permissions. Not appropriate for production environment 
sudo chmod 755 /var/www/html/ -R

# Setup Virtual Environment
cd CloudNine
sudo `which python3` env_setup/setup.py

# Setup Env variables
touch ecommerce/.env

echo "MYSQL_HOST='$MYSQL_HOST'
MYSQL_DB_NAME='$MYSQL_DB_NAME'
MYSQL_USER='$MYSQL_USER'
MYSQL_PASSWORD='$MYSQL_PASSWORD'
AZ_ACCOUNT_NAME='$AZ_ACCOUNT_NAME'
AZ_ACCOUNT_KEY='$AZ_ACCOUNT_KEY'
AZURE_SERVICE_BUS_QUEUE_NAME='$AZURE_SERVICE_BUS_QUEUE_NAME'
AZURE_SERVICE_BUS_CONNECTION_STRING='$AZURE_SERVICE_BUS_CONNECTION_STRING'" | tee /var/www/html/CloudNine/ecommerce/.env

# Load demo data
cd /var/www/html/CloudNine/ecommerce/
source /var/www/html/CloudNine/venv/ecom/bin/activate
# Create Tables
/var/www/html/CloudNine/venv/ecom/bin/python manage.py migrate

# Insert demo data
/var/www/html/CloudNine/venv/ecom/bin/python manage.py load_data

# Upload product images to azure storage 
# @TODO This command runs multiple times from each VM. Fix it to run it only for the first VM
/var/www/html/CloudNine/venv/ecom/bin/python manage.py upload_img

# Collect static files in azure storage
# @TODO This command runs multiple times from each VM. Fix it to run it only for the first VM
/var/www/html/CloudNine/venv/ecom/bin/python manage.py collectstatic --noinput 

# Setup SUpervisor
sudo cp /var/www/html/CloudNine/conf/ecom_supervisor.conf  /etc/supervisor/conf.d/
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl restart all

# Setup Nginx
sudo rm -rf /etc/nginx/sites-enabled/default
sudo cp /var/www/html/CloudNine/conf/ecom_nginx.conf  /etc/nginx/sites-available/
sudo ln -s /etc/nginx/sites-available/ecom_nginx.conf /etc/nginx/sites-enabled/

sudo systemctl restart nginx



