#!/bin/bash

echo "Setting up Laravel 5.5 development for your c9 environment..."
echo "   !!! DO NOT RUN THIS ON A PRODUCTION SERVER, DEAR GOD !!!"
echo "  MAKE SURE you select PHP/Apache container...then press enter"
read
. ~/.profile
echo "INSTALLING NOW!...."
pushd ~/workspace
rm hello-world.php
rm php.ini
rm README.md
sudo add-apt-repository -y ppa:ondrej/php
sudo apt-get update
sudo apt-get install -y php7.2 php7.2-xml php7.2-gd php7.2-mbstring libapache2-mod-php7.2 php7.2-mysql php7.2-zip
sudo a2dismod php5
sudo a2enmod php7.2
sudo composer self-update
sudo chown -R ubuntu:ubuntu ~/.composer
composer create-project --prefer-dist laravel/laravel laravel
mv laravel/* .
mv laravel/.env .
mv laravel/.env.example .
mv laravel/.gitattributes .
mv laravel/.gitignore .
rmdir laravel
sudo sed -i 's/DocumentRoot\ \/home\/ubuntu\/workspace/DocumentRoot\ \/home\/ubuntu\/workspace\/public/g' /etc/apache2/sites-enabled/001-cloud9.conf
sudo service apache2 restart
NVM_VERSION=$(nvm ls-remote | tail -n 1 | awk '{print $1}')
nvm install $NVM_VERSION
nvm use $NVM_VERSION
echo "RUNNING NPM INSTALL, THIS CAN TAKE A WHILE..."
npm install
npm cache verify
npm install
sudo service apache2 restart
sudo service mysql restart
sudo apt-get install mysql-server
sudo mysql_upgrade -u root --force --upgrade-system-tables
mysql -u root -e 'CREATE DATABASE laravel DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;'
sed -i 's/DB_DATABASE=homestead/DB_DATABASE=laravel/g' ~/workspace/.env
sed -i 's/DB_USERNAME=homestead/DB_USERNAME=root/g' ~/workspace/.env
sed -i 's/DB_PASSWORD=secret/DB_PASSWORD=/g' ~/workspace/.env
sed -i '16s/\/\//Schema::defaultStringLength(191);/g' app/Providers/AppServiceProvider.php
sed -i '4s/^$/\nuse Illuminate\\Support\\Facades\\Schema;/g' app/Providers/AppServiceProvider.php
php artisan migrate
echo "Done!"

