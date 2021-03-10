#!/bin/bash



if [ -n "$(uname -a | egrep -w 'Debian|Ubuntu')" ]; then
    bash /root/lamp/debian/lamp.sh 
else
    bash /root/lamp/centos/lamp.sh
fi 
