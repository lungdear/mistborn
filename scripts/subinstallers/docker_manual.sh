#!/bin/bash

# dependencies
echo "Installing Docker dependencies"
#sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg

# Docker repo key
echo "Adding docker repository key"
if [ "$DISTRO" == "ubuntu" ]; then
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
elif [ "$DISTRO" == "debian" ]; then
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
elif [ "$DISTRO" == "raspbian" ] || [ "$DISTRO" == "raspios" ]; then
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/raspbian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
fi

# Docker repo to source list
echo "Adding docker to sources list"
if [ "$DISTRO" == "ubuntu" ]; then
    echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
elif [ "$DISTRO" == "debian" ]; then
    echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
elif [ "$DISTRO" == "raspbian" ] || [ "$DISTRO" == "raspios" ]; then
    echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/raspbian \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
fi

# install Docker
echo "Installing docker"
sudo apt-get update

if [ "$DISTRO" == "ubuntu" ] || [ "$DISTRO" == "debian" ]; then
    sudo -E apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
elif [ "$DISTRO" == "raspbian" ] || [ "$DISTRO" == "raspios" ]; then
    sudo -E apt install -y --no-install-recommends \
    docker-ce \
    cgroupfs-mount
fi

# Docker group
sudo usermod -aG docker $USER

# Docker Compose
#echo "Installing Docker Compose"
#if [ "$DISTRO" == "ubuntu" ] || [ "$DISTRO" == "debian" ]; then
#    sudo curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
#    sudo chmod +x /usr/local/bin/docker-compose
#elif [ "$DISTRO" == "raspbian" ]; then
# Install required packages
#sudo -E apt install -y python-backports.ssl-match-hostname

# Install Docker Compose from pip
# This might take a while
# cryptography >=3.4 requires rust to compile, and no rust compiler is readily available for ARM
#sudo pip3 install cryptography==3.3.2 docker-compose
#sudo -E apt-get install -y docker-compose-plugin
#fi


# check raspbian fixes
if [ "$DISTRO" == "raspbian" ] || [ "$DISTRO" == "raspios" ]; then
    source ./scripts/subinstallers/docker_raspbian.sh 
fi
