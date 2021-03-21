#!/bin/bash

echo "    __                              __             __      _            __        ____"
echo "   / /___ _____ ___  ____     _____/ /_____ ______/ /__   (_)___  _____/ /_____ _/ / /"
echo "  / / __ \`/ __ \`__ \/ __ \   / ___/ __/ __ \`/ ___/ //_/  / / __ \/ ___/ __/ __ \`/ / / "
echo " / / /_/ / / / / / / /_/ /  (__  ) /_/ /_/ / /__/ ,<    / / / / (__  ) /_/ /_/ / / /  "
echo "/_/\__,_/_/ /_/ /_/ .___/  /____/\__/\__,_/\___/_/|_|  /_/_/ /_/____/\__/\__,_/_/_/   "
echo "                 /_/                                                                  "


if [[ "$EUID" -ne 0 ]]; then
  echo -e '\nERROR!!! SCRIPT MUST RUN WITH ROOT PRIVILEGES\n'
  exit 1
fi

if [[ -n "$(uname -a | egrep -w 'Debian|Ubuntu')" ]]; then
    . /root/lamp/debian/lamp.sh 
else
    . /root/lamp/centos/lamp.sh
fi 
