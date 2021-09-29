#!/bin/bash
set -e

LIB_PATH = "/opt"
NETBOX_VERSION = "3.0.3"
NGINX_VERSION = "1.18.0-0ubuntu1.2"

# Update Ubuntu
sudo apt-get update -y

####################################
#POSTGRES
# Install Postgres & start service
printf "Step 2 of 19: Installing & starting Postgres..."
apt-get install postgresql libpq-dev -y > /dev/null
sudo service postgresql start

# Setup Postgres with netbox user, database, and permissions
printf "Step 3 of 19: Setup Postgres with netbox user, database, & permissions."
sudo -u postgres psql -c "CREATE DATABASE netbox"
sudo -u postgres psql -c "CREATE USER netbox WITH PASSWORD 'J5brHrAXFLQSif0K'"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE netbox TO netbox"
##########################################################

#install required system packages <-- TODO confirm which packages can be excluded
sudo apt install -y python3 python3-pip python3-venv python3-dev build-essential libxml2-dev libxslt1-dev libffi-dev libpq-dev libssl-dev zlib1g-dev
#Go to directory for the NetBox installation
cd "$LIB_PATH"
#Download and untar NetBox release
wget sudo wget https://github.com/netbox-community/netbox/archive/v$NETBOX_VERSION.tar.gz
sudo tar -xzf v$NETBOX_VERSION.tar.gz -C $LIB_PATH
sudo ln -sf $LIB_PATH/netbox-$NETBOX_VERSION/ $LIB_PATH/netbox
#Install required packages with version equal or grater than not to downgrade golden image packages
sudo sed -i -e "s/==/>=/g" "$LIB_PATH"/netbox/requirements.txt
python -m pip install --ignore-installed -r "$LIB_PATH"/netbox/requirements.txt
#install redis
sudo apt install -y redis-server
#verify redis status
redis-cli ping #<- handle the pong
#make sure that that pip is in lastest release
sudo pip3 install --upgrade pip
#create NetBox user and change permissions
sudo adduser --system --group netbox
sudo chown --recursive netbox "$LIB_PATH"/netbox/netbox/media/
#configure NetBox
cd "$LIB_PATH"/netbox/netbox/netbox/
sudo cp configuration.example.py configuration.py
#allow all hosts
sudo sed -i -e "s/ALLOWED_HOSTS\s=\s\[\]/ALLOWED_HOSTS = ['*']/g" configuration.py
#TODO: handle PostgreSQL name/user/password/host/port
#sed -i "s/'USER': '',  /'USER': 'netbox',  /g" configuration.py
#sed -i "s/'PASSWORD': '',  /'PASSWORD': 'J5brHrAXFLQSif0K',  /g" configuration.py
#sed -i "s/'HOST': 'localhost',  /'HOST': 'database.rds.amazonaws.com',  /g" configuration.py
#sed -i "s/'PORT': '',  /'PORT': '5432',  /g" configuration.py

#generate and supply secret key for encryption
secret_key=$(python3 ./../generate_secret_key.py)
sed -i -e "s/SECRET_KEY\s=\s''/SECRET_KEY = '$secret_key'/g" configuration.py
# Clear secret_key variable
unset secret_key
#run upgrade script
sudo "$LIB_PATH"/netbox/upgrade.sh
#Create a Super User for NetBox
source "$LIB_PATH"/netbox/venv/bin/activate
#create NetBox power user
echo "from django.contrib.auth.models import User; User.objects.create_superuser('spirent', 'spirent@spirent.com', 'spirent')" | python3 "$LIB_PATH"/netbox/netbox/manage.py shell
#escape virtualenv
deactivate
#Schedule the Housekeeping Task
cp "$LIB_PATH"/netbox/contrib/netbox-housekeeping.sh /etc/cron.daily/
#configure Gunicorn
sudo cp "$LIB_PATH"/netbox/contrib/gunicorn.py "$LIB_PATH"/netbox/gunicorn.py
#systemd setup
sudo cp -v "$LIB_PATH"/netbox/contrib/*.service /etc/systemd/system/
sudo systemctl daemon-reload
#starting netbox and netbox-rq and enable them to initiate at boot time
sudo systemctl start netbox netbox-rq
sudo systemctl enable netbox netbox-rq
#verify status
systemctl status netbox.service
#install nginx
sudo apt-get install -y nginx=$NGINX_VERSION
#configure nginx
sudo cp "$LIB_PATH"/netbox/contrib/nginx.conf /etc/nginx/sites-available/netbox
sudo rm /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/netbox /etc/nginx/sites-enabled/netbox
sudo systemctl restart nginx
private_IP=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
sudo sed -i -e "s/netbox.example.com/$private_ip/g" /etc/nginx/sites-available/netbox

#TODO: handle SSL certificate in nginx
