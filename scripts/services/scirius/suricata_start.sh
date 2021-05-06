#!/bin/bash

systemctl stop suricata

IFACE=$(ip -o -4 route show to default | awk 'NR==1{print $5}')
sudo sed -i "s/eth0/${IFACE}/g" /etc/suricata/suricata.yaml
sudo sed -i "s/eth0/${IFACE}/g" /etc/default/suricata

systemctl start suricata
systemctl enable suricata

apt-get install -y python-pyinotify python-daemon
python /opt/mistborn/scripts/services/scirius/suri_reloader -p /etc/suricata/rules -D