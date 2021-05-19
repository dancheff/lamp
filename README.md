## Description
LAMP is a powerful bash script for installation. You install with it Apache, PHP, MySQL/MariaDB, phpMyAdmin in a very easy and fast way. With the option to create an account in phpMyAdmin.

## Supported System
* CentOS-6.x
* CentOS-7.x (recommend)
* Debian-8.x
* Debian-9.x
* Debian-10.x (recommend)
* Ubuntu-16.x
* Ubuntu-18.x
* Ubuntu-20.x (recommend)

## Software Version
* Apache - 2.4
* MariaDB - 10.5.9 (up to date: 10.03.2021)
* PHP - 7.3.27
* phpMyAdmin (PHP 7.1+) - 5.1.0 (up to date: 10.03.2021)

## Installation
```bash
apt update && apt -y install wget git  # If your server system is: Debian/Ubuntu
yum install -y wget git  # If your server system is: CentOS
git clone https://github.com/dancheff/lamp.git
cd lamp
chmod +x install.sh
./install.sh
```

## Bugs & Issues
Please feel free to report any bugs or issues to us, email to: valentin@dancheff.com or [open issue](http://github.com/dancheff/lamp/issues) on Github.
