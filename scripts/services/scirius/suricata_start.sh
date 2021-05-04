#!/bin/bash

systemctl start suricata
systemctl enable suricata

python /opt/mistborn/scripts/services/scirius/suri_reloader -D 