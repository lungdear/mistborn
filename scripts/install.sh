#!/bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive

#IPV4_PUBLIC=$(ip -o -4 route show default | egrep -o 'dev [^ ]*' | awk '{print $2}' | xargs ip -4 addr show | grep 'inet ' | awk '{print $2}' | grep -o "^[0-9.]*"  | tr -cd '\11\12\15\40-\176' | head -1) # tail -1 to get last
export IPV4_PUBLIC="10.2.3.1"

# check that git exists
if ! [ -x "$(command -v git)" ]; then
    echo "Installing git"
    sudo apt-get install -y git
fi

## ensure run as nonroot user
#if [ "$EUID" -eq 0 ]; then
MISTBORN_USER="mistborn"
if [ $(whoami) != "$MISTBORN_USER" ]; then
        echo "Creating user: $MISTBORN_USER"
        sudo useradd -s /bin/bash -d /home/$MISTBORN_USER -m -G sudo $MISTBORN_USER 2>/dev/null || true
        SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
        #echo "SCRIPTPATH: $SCRIPTPATH"
        FILENAME=$(basename -- "$0")
        #echo "FILENAME: $FILENAME"
        FULLPATH="$SCRIPTPATH/$FILENAME"
        #echo "FULLPATH: $FULLPATH"

        # SUDO
        case `sudo grep -e "^$MISTBORN_USER.*" /etc/sudoers >/dev/null; echo $?` in
        0)
            echo "$MISTBORN_USER already in sudoers"
            ;;
        1)
            echo "Adding $MISTBORN_USER to sudoers"
            sudo bash -c "echo '$MISTBORN_USER  ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers"
            ;;
        *)
            echo "There was a problem checking sudoers"
            ;;
        esac
       
        # get git branch if one exists (default to master)
        pushd .
        cd $SCRIPTPATH
        GIT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "master")
        popd

        sudo cp $FULLPATH /home/$MISTBORN_USER
        sudo chown $MISTBORN_USER:$MISTBORN_USER /home/$MISTBORN_USER/$FILENAME
        sudo chmod 700 /home/$MISTBORN_USER/$FILENAME
        sudo SSH_CLIENT="$SSH_CLIENT" MISTBORN_DEFAULT_PASSWORD="$MISTBORN_DEFAULT_PASSWORD" GIT_BRANCH="$GIT_BRANCH" MISTBORN_INSTALL_COCKPIT="$MISTBORN_INSTALL_COCKPIT" -i -u $MISTBORN_USER bash -c "/home/$MISTBORN_USER/$FILENAME" # self-referential call
        exit 0
fi

echo "Running as $USER"

# banner

# check that figlet exists
if ! [ -x "$(command -v figlet)" ]; then
    echo "Installing figlet"
    sudo apt-get install -y figlet
fi

figlet "Stormblest"
figlet "Mistborn"

sudo rm -rf /opt/mistborn 2>/dev/null || true

# clone to /opt and change directory
echo "Cloning $GIT_BRANCH branch from mistborn repo"
sudo git clone https://gitlab.com/cyber5k/mistborn.git -b $GIT_BRANCH /opt/mistborn
sudo chown -R $USER:$USER /opt/mistborn
pushd .
cd /opt/mistborn
git submodule update --init --recursive

# Check updates
echo "Checking updates"
source ./scripts/subinstallers/check_updates.sh

# Check ready for installation
echo "Checking system readiness for mistborn installation"
source ./scripts/subinstallers/check_install_ready.sh

# MISTBORN_DEFAULT_PASSWORD
source ./scripts/subinstallers/passwd.sh

# Install Cockpit?
if [ -z "${MISTBORN_INSTALL_COCKPIT}" ]; then
    #MISTBORN_INSTALL_COCKPIT=Y
    read -p "Install Cockpit (a somewhat resource-heavy system management graphical user interface -- NOT RECOMMENDED on Raspberry Pi)? [y/N]: " MISTBORN_INSTALL_COCKPIT
    echo
    MISTBORN_INSTALL_COCKPIT=${MISTBORN_INSTALL_COCKPIT:-N}
fi

# SSH keys
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "Generating SSH keypair for $USER"
    ssh-keygen -t rsa -b 4096 -N "" -m pem -f ~/.ssh/id_rsa -q
    
    # Authorized keys
    echo "from=\"172.16.0.0/12,192.168.0.0/16,10.0.0.0/8\" $(cat ~/.ssh/id_rsa.pub)" > ~/.ssh/authorized_keys
else
    echo "SSH key exists for $USER"
fi

# initial load update package list during check_updates.sh

# install figlet
sudo -E apt-get install -y figlet

# get os and distro
source ./scripts/subinstallers/platform.sh


# iptables
echo "Setting up firewall (iptables)"
if [ -f "/etc/iptables/rules.v4" ]; then
    echo "Caution: iptables rules exist."

    read -p "Would you like to Clear (C) existing iptables rules or Add (A) to existing rules (this may cause problems)? [c/a] " MISTBORN_IPTABLES_ACTION
    echo

    if [[ "${MISTBORN_IPTABLES_ACTION}" =~ ^([cC])$ ]]; then
    # clear
        echo "Clearing existing iptables rules..."
        sudo rm -rf /etc/iptables/rules.v4
        sudo iptables -F
        sudo iptables -t nat -F
        sudo iptables -P INPUT ACCEPT
        sudo iptables -P FORWARD ACCEPT
        sudo rm -rf /etc/iptables/rules.v6 || true
        sudo ip6tables -F || true
        sudo ip6tables -t nat -F || true
        sudo ip6tables -P INPUT ACCEPT || true
        sudo ip6tables -P FORWARD ACCEPT || true

    elif [[ "${MISTBORN_IPTABLES_ACTION}" =~ ^([aA])$ ]]; then
    # do nothing
        echo "Proceeding..."

    else
        echo "Unrecognized action: stopping"
        exit 1;

    fi
fi

echo "Setting iptables rules..."
source ./scripts/subinstallers/iptables.sh

# SSH Server
sudo -E apt-get install -y openssh-server
#sudo sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
#sudo sed -i 's/PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
#sudo sed -i 's/#PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
#sudo sed -i 's/PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
sudo sed -i 's/#Port.*/Port 22/' /etc/ssh/sshd_config
sudo sed -i 's/Port.*/Port 22/' /etc/ssh/sshd_config
sudo systemctl enable ssh
sudo systemctl restart ssh

# Additional tools fail2ban
sudo -E apt-get install -y dnsutils fail2ban

# Install kernel headers
if [ "$DISTRO" == "ubuntu" ] || [ "$DISTRO" == "debian" ]; then
    sudo -E apt install -y linux-headers-$(uname -r)
elif [ "$DISTRO" == "raspbian" ] || [ "$DISTRO" == "raspios" ]; then
    sudo -E apt install -y raspberrypi-kernel-headers
else
    echo "Unsupported OS: $DISTRO"
    exit 1
fi

# Wireugard
source ./scripts/subinstallers/wireguard.sh

# Docker
source ./scripts/subinstallers/docker.sh
sudo systemctl enable docker
sudo systemctl start docker

# Unattended upgrades
sudo -E apt-get install -y unattended-upgrades

# Cockpit
if [[ "$MISTBORN_INSTALL_COCKPIT" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    # install cockpit
    source ./scripts/subinstallers/cockpit.sh
    
    # set variable (that will be available in environment)
    MISTBORN_INSTALL_COCKPIT=Y
fi

# Mistborn-cli (pip3 installed by docker)
figlet "Mistborn: Installing mistborn-cli"
#sudo -E apt-get install -y pipx
#pipx ensurepath
#pipx install -e ./modules/mistborn-cli
sudo pip3 install -e ./modules/mistborn-cli 2>/dev/null || \
    sudo pip3 install -e ./modules/mistborn-cli --break-system-packages

# Mistborn
# final setup vars


# generate production .env file
#if [ ! -d ./.envs/.production ]; then
./scripts/subinstallers/gen_prod_env.sh "$MISTBORN_DEFAULT_PASSWORD"
#fi

# unattended upgrades
sudo cp ./scripts/conf/20auto-upgrades /etc/apt/apt.conf.d/
sudo cp ./scripts/conf/50unattended-upgrades /etc/apt/apt.conf.d/

sudo systemctl stop unattended-upgrades
sudo systemctl daemon-reload
sudo systemctl restart unattended-upgrades

# setup Mistborn services

#if [ "$DISTRO" == "debian" ] || [ "$DISTRO" == "raspbian" ]; then
#    # remove systemd-resolved lines
#    sudo sed -i '/.*systemd-resolved/d' /etc/systemd/system/Mistborn-base.service
#fi

# setup local volumes for pihole
sudo mkdir -p ../mistborn_volumes/
sudo chown -R root:root ../mistborn_volumes/
sudo mkdir -p ../mistborn_volumes/base/pihole/etc-pihole
sudo mkdir -p ../mistborn_volumes/base/pihole/etc-dnsmasqd
sudo mkdir -p ../mistborn_volumes/extra

# Traefik final setup (cockpit)
#cp ./compose/production/traefik/traefikv2.toml.template ./compose/production/traefik/traefik.toml

# setup tls certs 
source ./scripts/subinstallers/openssl.sh
#sudo rm -rf ../mistborn_volumes/base/tls
#sudo mv ./tls ../mistborn_volumes/base/

# enable and run setup
sudo cp ./scripts/services/Mistborn-setup.service /etc/systemd/system/
sudo systemctl enable Mistborn-setup.service
sudo systemctl start Mistborn-setup.service

# Download docker images while DNS is operable
sg docker -c "docker compose -f base.yml pull || true"
sg docker -c "docker compose -f base.yml build"

## disable systemd-resolved stub listener (creates symbolic link to /etc/resolv.conf)
if [ -f /etc/systemd/resolved.conf ]; then
    sudo sed -i 's/#DNSStubListener.*/DNSStubListener=no/' /etc/systemd/resolved.conf
    sudo sed -i 's/DNSStubListener.*/DNSStubListener=no/' /etc/systemd/resolved.conf
fi

## delete symlink if exists
if [ -L /etc/resolv.conf ]; then
    sudo rm /etc/resolv.conf
fi

## disable other DNS services
sudo systemctl stop systemd-resolved 2>/dev/null || true
sudo systemctl disable systemd-resolved 2>/dev/null || true
sudo systemctl stop dnsmasq 2>/dev/null || true
sudo systemctl disable dnsmasq 2>/dev/null || true

# hostname in /etc/hosts
sudo grep -qF "$(hostname)" /etc/hosts && echo "$(hostname) already in /etc/hosts" || echo "127.0.1.1 $(hostname) $(hostname)" | sudo tee -a /etc/hosts

# backups
echo "backup up original volumes folder"
sudo mkdir -p ../mistborn_backup
sudo chmod 700 ../mistborn_backup
sudo tar -czf ../mistborn_backup/mistborn_volumes_backup.tar.gz ../mistborn_volumes 1>/dev/null 2>&1

# clean docker
echo "cleaning old docker volumes"
sudo systemctl stop Mistborn-base || true
sudo docker compose -f /opt/mistborn/base.yml kill
sudo docker volume rm -f mistborn_production_postgres_data 2>/dev/null || true
sudo docker volume rm -f mistborn_production_postgres_data_backups 2>/dev/null || true
sudo docker volume rm -f mistborn_production_traefik 2>/dev/null || true
sudo docker volume prune -f 2>/dev/null || true

# clean Wireguard
echo "cleaning old wireguard services"
sudo ./scripts/env/wg_clean.sh

# start base service
sudo systemctl enable Mistborn-base.service
sudo systemctl start Mistborn-base.service
popd

figlet "Mistborn Installed"
echo "Watch Mistborn start: sudo journalctl -xfu Mistborn-base"
echo "Retrieve Wireguard default config for admin: sudo mistborn-cli getconf" 
