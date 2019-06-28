#!/bin/bash

echo "Setting up Laravel development for your aws c9 environment..."
echo "   !!! DO NOT RUN THIS ON A PRODUCTION SERVER, DEAR GOD !!!"
echo "Hit enter to continue"
read
echo "INSTALLING NOW!...."
echo "Waiting for cloud apt to stop so we can install things"
echo "This may take anywhere from 1 to 5 minutes... You can check status by doing 'ps aux | grep apt'"
while ps aux | grep apt | grep -v grep > /dev/null
do
           sleep 1;
done
sudo fallocate -l 1G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
sudo apt update
sudo apt -y upgrade
sudo apt install -y apache2 php libapache2-mod-php php-xml php-gd php-mbstring php-mysql php-zip php-bcmath php-json php-tokenizer
sudo apt install -y mysql-server 
sudo service mysql start
sudo service apache2 start
sudo apt install -y composer
sudo a2enmod rewrite
sudo groupadd web-content
sudo usermod -G web-content -a ubuntu
sudo usermod -G web-content -a www-data
mkdir ~/.composer
sudo chown -R ubuntu:ubuntu /home/ubuntu/.composer
sudo chmod -R 777 /home/ubuntu/.composer
cd /var/www/html
sudo composer create-project --prefer-dist laravel/laravel laravel
sudo chown -R ubuntu:web-content /var/www/html
sudo find /var/www/html -type f -exec chmod u=rw,g=rx,o=rx {} \;
sudo find /var/www/html -type d -exec chmod u=rwx,g=rx,o=rx {} \;
chmod -R 777 /var/www/html/laravel/storage
sudo chmod g+s /var/www/html
sudo sed -i 's/DocumentRoot\ \/var\/www\/html/DocumentRoot\ \/var\/www\/html\/laravel\/public/g' /etc/apache2/sites-enabled/000-default.conf
sudo service apache2 restart
NVM_VERSION=$(nvm ls-remote | tail -n 1 | awk '{print $1}')
nvm install $NVM_VERSION
nvm use $NVM_VERSION
echo "RUNNING NPM INSTALL, THIS CAN TAKE A WHILE..."
cd /var/www/html/laravel
composer require guzzlehttp/guzzle
npm install
npm cache verify
npm install
npm run dev
sudo mysql_upgrade -u root --force --upgrade-system-tables
sudo mysql -u root -e "DROP USER 'root'@'localhost';CREATE USER 'root'@'%' IDENTIFIED BY '';GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;FLUSH PRIVILEGES;"
mysql -u root -e 'CREATE DATABASE laravel DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;'
ln -s /var/www/html/laravel ~/environment/laravel
rm ~/environment/README.md
sed -i 's/DB_DATABASE=homestead/DB_DATABASE=laravel/g' /var/www/html/laravel/.env
sed -i 's/DB_USERNAME=homestead/DB_USERNAME=root/g' /var/www/html/laravel/.env
sed -i 's/DB_PASSWORD=secret/DB_PASSWORD=/g' /var/www/html/laravel/.env
sed -i '16s/\/\//Schema::defaultStringLength(191);/g' /var/www/html/laravel/app/Providers/AppServiceProvider.php
sed -i '4s/^$/\nuse Illuminate\\Support\\Facades\\Schema;/g' /var/www/html/laravel/app/Providers/AppServiceProvider.php
sudo sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf
sudo service apache2 restart
sudo service mysql restart
php artisan migrate
echo "Done installing"
echo "Configuring AWS to allow apache"

# Get the ID of the instance for the environment, and store it temporarily.
MY_INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id) 
           
# Get the ID of the security group associated with the instance, and store it temporarily.
MY_SECURITY_GROUP_ID=$(aws ec2 describe-instances --instance-id $MY_INSTANCE_ID --query 'Reservations[].Instances[0].SecurityGroups[0].GroupId' --output text)

# Add an inbound rule to the security group to allow all incoming IPv4-based traffic over port 80.
aws ec2 authorize-security-group-ingress --group-id $MY_SECURITY_GROUP_ID --protocol tcp --cidr 0.0.0.0/0 --port 80

# Add an inbound rule to the securty group to allow all incoming IPv6-based traffic over port 80.
aws ec2 authorize-security-group-ingress --group-id $MY_SECURITY_GROUP_ID --ip-permissions IpProtocol=tcp,Ipv6Ranges='[{CidrIpv6=::/0}]',FromPort=80,ToPort=80

# Get the ID of the subnet associated with the instance, and store it temporarily.
MY_SUBNET_ID=$(aws ec2 describe-instances --instance-id $MY_INSTANCE_ID --query 'Reservations[].Instances[0].SubnetId' --output text)

# Get the ID of the network ACL associated with the subnet, and store it temporarily.
MY_NETWORK_ACL_ID=$(aws ec2 describe-network-acls --filters Name=association.subnet-id,Values=$MY_SUBNET_ID --query 'NetworkAcls[].Associations[0].NetworkAclId' --output text)

# Add an inbound rule to the network ACL to allow all IPv4-based traffic over port 80. Advanced users: change this suggested rule number as desired.
aws ec2 create-network-acl-entry --network-acl-id $MY_NETWORK_ACL_ID --ingress --protocol tcp --rule-action allow --rule-number 10000 --cidr-block 0.0.0.0/0 --port-range From=80,To=80

# Add an inbound rule to the network ACL to allow all IPv6-based traffic over port 80. Advanced users: change this suggested rule number as desired.
aws ec2 create-network-acl-entry --network-acl-id $MY_NETWORK_ACL_ID --ingress --protocol tcp --rule-action allow --rule-number 10100 --ipv6-cidr-block ::/0 --port-range From=80,To=80


MY_PUBLIC_IP=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
echo http://$MY_PUBLIC_IP/ > ~/environment/URL.txt
echo ""
echo ""
sudo service apache2 restart
echo "Done!  Browse to http://$MY_PUBLIC_IP/"
