#!/bin/bash



if [  -n "$(uname -a | grep Ubuntu | grep Debian)" ]; then
    bash /lamp/debian/lamp.sh 
else
    bash /lamp/centos/lamp.sh
fi 
