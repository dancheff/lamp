#!/bin/bash

# Name: lamp.sh
# Created By: dancheff
# Description: Automagically installs the LAMP Server
# OS: Ubuntu/Debian

set -e # exit with a non-zero status when there is an uncaught error

# colors
Red="\033[0;31m"         
Green="\033[0;32m"        
Color_Off="\033[0m"       

bold="\e[1m"
normal="\e[0m"

EXTERNAL_IP=$(wget -qO - http://geoip.ubuntu.com/lookup | sed -n -e 's/.*<Ip>\(.*\)<\/Ip>.*/\1/p')

# update system
echo -e "${Green}\n Updating System..${Color_Off}"
sleep 2
apt update -y
apt -y install software-properties-common gnupg2 pwgen wget unzip
add-apt-repository ppa:ondrej/php
apt -y upgrade

# install apache  
echo -e "${Green}\n Installing Apache2, PHP & Requirements${Color_Off}"
sleep 2
apt install apache2 apache2-utils libapache2-mod-php -y
apt install php-json php-xml php php-pdo php-zip php-common php-fpm php-mbstring php-cli php-mysql -y
#apt install php7.1 php7.1-cli php7.1-common php7.1-json php7.1-opcache php7.1-mysql php7.1-mbstring php7.1-mcrypt php7.1-zip php7.1-fpm -y

# install mysql
echo -e "${Green}\n Installing MySQL${Color_Off}"
sleep 2
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xF1656F24C74CD1D8
#add-apt-repository "deb [arch=amd64] http://mariadb.mirror.liquidtelecom.com/repo/10.5/debian $(lsb_release -cs) main"
add-apt-repository 'deb [arch=amd64] http://mariadb.mirror.liquidtelecom.com/repo/10.5/debian/ buster main'
apt update
apt install mariadb-server mariadb-client -y

# download and install phpmyadmin
wget https://files.phpmyadmin.net/phpMyAdmin/5.1.0/phpMyAdmin-5.1.0-all-languages.zip
unzip phpMyAdmin-5.1.0-all-languages.zip
mv phpMyAdmin-5.1.0-all-languages /usr/share/phpMyAdmin
cp -pr /usr/share/phpMyAdmin/config.sample.inc.php /usr/share/phpMyAdmin/config.inc.php
export SECRET=`php -r 'echo base64_encode(random_bytes(24));'`
echo "\$cfg['blowfish_secret'] = '$SECRET';" >> /usr/share/phpMyAdmin/config.inc.php
rm -rf phpMyAdmin-5.1.0-all-languages.zip
mkdir /usr/share/phpMyAdmin/tmp
chmod 777 /usr/share/phpMyAdmin/tmp
chown -R www-data:www-data /usr/share/phpMyAdmin

# create database
mysql < /usr/share/phpMyAdmin/sql/create_tables.sql -u root

# phpmyadmin config
touch /etc/apache2/sites-available/phpmyadmin.conf
cat > /etc/apache2/sites-available/phpmyadmin.conf <<EOF
#Alias /phpMyAdmin /usr/share/phpMyAdmin
Alias /phpmyadmin /usr/share/phpMyAdmin
<Directory /usr/share/phpMyAdmin/>
   AddDefaultCharset UTF-8
   <IfModule mod_authz_core.c>
     # Apache 2.4
     <RequireAny> 
      Require all granted
     </RequireAny>
   </IfModule>
   <IfModule !mod_authz_core.c>
     # Apache 2.2
     Order Deny,Allow
     Deny from All
     Allow from 127.0.0.1
     Allow from ::1
   </IfModule>
</Directory>
<Directory /usr/share/phpMyAdmin/setup/>
   <IfModule mod_authz_core.c>
     # Apache 2.4
     <RequireAny>
       Require all granted
     </RequireAny>
   </IfModule>
   <IfModule !mod_authz_core.c>
     # Apache 2.2
     Order Deny,Allow
     Deny from All
     Allow from 127.0.0.1
     Allow from ::1
   </IfModule>
</Directory>
EOF

sudo a2ensite phpmyadmin
# 
# create phpmyadmin user
echo -ne "${Green}\nCreate a user for phpMyAdmin:${Color_Off} "; read username
PASS=`pwgen -s 20 1`

mysql -u root << MYSQL_SCRIPT
CREATE USER '$username'@'localhost' IDENTIFIED BY '$PASS';
GRANT ALL PRIVILEGES ON *.* TO '$username'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# change dir for phpmyadmin
echo -e "${Green}The default phpMyAdmin directory is:${Color_Off} ${Red}http://$EXTERNAL_IP/${bold}phpmyadmin${normal}${Color_Off}"
echo -e "${Green}You have the opportunity to change it:${Color_Off} ${Red}http://$EXTERNAL_IP/${bold}yourchoice${normal}${Color_Off}"
while true; do
  echo -ne "${Green}Do you want to change the directory?${Color_Off} ${bold}${Green}[Y/n]:${Color_Off}${normal} "; read answer
  if [[ $answer =~ [Yy] ]]; then
    echo -ne "${Green}Please enter a directory for phpMyAdmin:$Color_Off "; read phpdir
    if [[ $phpdir =~ ^[[:alnum:]]+$ ]]; then
      phpdir=$(echo $phpdir | sed -e 's/[\/&]/\\&/g')
      sed -i 's/phpmyadmin/'$phpdir'/g' /etc/apache2/sites-available/phpmyadmin.conf
      echo -e "${Green}\nYou have successfully changed the phpMyAdmin directory!${Color_Off}"
      echo -e "${Green}The installation is ready!\n${Color_Off}"
      echo -e "${Green}You can access your phpMyAdmin at: http://$EXTERNAL_IP/$phpdir${Color_Off}"
      echo -e "${Green}Username: $username${Color_Off}"
      echo -e "${Green}Password: $PASS${Color_Off}"
      break;
    else
      echo -e "${Red}\nYour directory contains special characters! Please try again!${Color_Off}"
    fi
  elif [[ $answer =~ [Nn] ]]; then
    echo -e "${Green}The installation is ready!\n${Color_Off}"
    echo -e "${Green}\nYou can access your phpMyAdmin at: http://$EXTERNAL_IP/phpmyadmin${Color_Off}"
    echo -e "${Green}Username: $username${Color_Off}"
    echo -e "${Green}Password: $PASS${Color_Off}"
    break;
  fi
done

# restart apache  
sudo systemctl reload apache2
exit 0
