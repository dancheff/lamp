#!/bin/bash

# Name: lamp.sh
# Created By: dancheff
# Description: Automagically installs the LAMP Server
# OS: CentOS

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
yum -y update
yum install -y firewalld wget unzip
systemctl enable firewalld
systemctl start firewalld

# install apache  
echo -e "${Green}\n Installing Apache, PHP & Requirements${Color_Off}"
sleep 2
yum -y install httpd
yum install -y epel-release yum-utils
yum install -y http://rpms.remirepo.net/enterprise/remi-release-7.rpm
sudo yum-config-manager --enable remi-php73
yum install -y php php-common php-opcache php-mcrypt php-mbstring php-soap php-cli php-gd php-curl php-mysqlnd php-pdo php-ldap php-odbc php-pear php-xml php-xmlrpc
firewall-cmd --permanent --zone=public --add-service=http
firewall-cmd --permanent --zone=public --add-service=https
firewall-cmd --reload
systemctl enable httpd
systemctl start httpd

# install mysql
echo -e "${Green}\n Installing MySQL${Color_Off}"
sleep 2
wget https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
echo "6528c910e9b5a6ecd3b54b50f419504ee382e4bdc87fa333a0b0fcd46ca77338 mariadb_repo_setup" | sha256sum -c
chmod +x mariadb_repo_setup
./mariadb_repo_setup --mariadb-server-version="mariadb-10.5"
yum install -y MariaDB-server MariaDB-backup
systemctl enable mariadb
systemctl start mariadb

# download and install phpmyadmin
echo -e "${Green}\n Installing phpMyAdmin${Color_Off}"
sleep 2
wget https://files.phpmyadmin.net/phpMyAdmin/5.1.0/phpMyAdmin-5.1.0-all-languages.zip
unzip phpMyAdmin-5.1.0-all-languages.zip
mv phpMyAdmin-5.1.0-all-languages /usr/share/phpMyAdmin
cp -pr /usr/share/phpMyAdmin/config.sample.inc.php /usr/share/phpMyAdmin/config.inc.php
export SECRET=`php -r 'echo base64_encode(random_bytes(24));'`
echo "\$cfg['blowfish_secret'] = '$SECRET';" >> /usr/share/phpMyAdmin/config.inc.php
rm -rf phpMyAdmin-5.1.0-all-languages.zip
mkdir /usr/share/phpMyAdmin/tmp
chmod 777 /usr/share/phpMyAdmin/tmp
chown -R apache:apache /usr/share/phpMyAdmin

# create database
mysql < /usr/share/phpMyAdmin/sql/create_tables.sql -u root

# phpmyadmin config
touch /etc/httpd/conf.d/phpmyadmin.conf
cat > /etc/httpd/conf.d/phpmyadmin.conf <<EOF
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

# create phpmyadmin user
yum install -y pwgen
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
      sed -i 's/phpmyadmin/'$phpdir'/g' /etc/httpd/conf.d/phpmyadmin.conf
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
systemctl restart httpd
exit 0
