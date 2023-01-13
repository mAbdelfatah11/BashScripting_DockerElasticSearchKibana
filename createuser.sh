#!/bin/bash
useradd -p "WB-Services2022" -G sudo -m -d /home/WB-Services -s /bin/bash WB-Services
#execute sudo commands without password
echo "WB-Services ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

su - WB-Services
