#!/bin/bash

set -e

MISTBORN_SERVICES_TABLE="$1"

# reset if it already exists
sudo iptables -X MISTBORN_SERVICES_LE 2>/dev/null || true

# create chain
sudo iptables -N MISTBORN_SERVICES_LE

# set rules
sudo iptables -A MISTBORN_SERVICES_LE -s 10.0.0.0/8 -j RETURN
sudo iptables -A MISTBORN_SERVICES_LE -s 172.16.0.0/12 -j RETURN
sudo iptables -A MISTBORN_SERVICES_LE -s 192.168.0.0/16 -j RETURN
sudo iptables -A MISTBORN_SERVICES_LE -p tcp --dport 80 -j ACCEPT # run the port 80 check again

# set start
sudo iptables -A ${MISTBORN_SERVICES_TABLE} -p tcp --dport 80 -j MISTBORN_SERVICES_LE
