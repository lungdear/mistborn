#!/bin/bash

# Cockpit
figlet "Mistborn: Installing Cockpit"
# if [ "$DISTRO" == "ubuntu" ]; then
#     echo "Ubuntu backports enabled by default"

# elif [ "$DISTRO" == "debian" ]; then
#     sudo grep -qF "buster-backports" /etc/apt/sources.list.d/backports.list \
#     && echo "buster-backports already in sources" \
#     || echo 'deb http://deb.debian.org/debian buster-backports main' | sudo tee -a /etc/apt/sources.list.d/backports.list
    
# elif [ "$DISTRO" == "raspbian" ] || [ "$DISTRO" == "raspios" ]; then
#     echo "Raspbian repos contain cockpit"
# fi
    
sudo -E apt-get install -y cockpit

if [ $(sudo apt-cache show cockpit-docker > /dev/null 2>&1) ]; then
    # no longer supported upstream in Ubuntu 20.04
    sudo -E apt-get install -y cockpit-docker
elif [ $(sudo apt-cache show cockpit-podman > /dev/null 2>&1) ]; then
    sudo -E apt-get install -y cockpit-podman
fi

sudo cp ./scripts/conf/cockpit.conf /etc/cockpit/cockpit.conf
sudo sed -i "s/IPV4_PUBLIC/$IPV4_PUBLIC/g" /etc/cockpit/cockpit.conf
sudo systemctl restart cockpit.socket

# create system cockpit user
echo "Creating cockpit user"
sudo useradd -s /bin/bash -d /home/cockpit -m -G sudo -p $(openssl passwd -1 "$MISTBORN_DEFAULT_PASSWORD") cockpit || true
sudo -u cockpit ssh-keygen -t rsa -b 4096 -N "" -f /home/cockpit/.ssh/id_rsa || true
