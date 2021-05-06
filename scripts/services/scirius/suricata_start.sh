#!/bin/bash

systemctl start suricata
systemctl enable suricata

apt-get install -y python-pyinotify python-daemon
python /opt/mistborn/scripts/services/scirius/suri_reloader &