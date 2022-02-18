#!/bin/bash


valid_server_ip() {
python3 << END

import sys
import ipaddress

try:
    ip = ipaddress.ip_address("$1")

    if not isinstance(ip, ipaddress.IPv4Address):
        print('Not an IPv4 address')
        sys.exit(-1)
    
    if ipaddress.ip_network("$1").subnet_of(ipaddress.ip_network('10.3.0.0/16')):
        #print('valid address')
        sys.exit(0)
    
    #print('invalid address')
    sys.exit(-1)

except Exception as e:
    sys.exit(-1)

END
}

MISTBORN_INTERNAL_IP="0.0.0.0"
until valid_server_ip "${MISTBORN_INTERNAL_IP}"; do

    >&2 echo "(Mistborn) Enter a valid IP address in 10.3.0.0/16"
    read -p "(Mistborn) Set server IP: [10.3.3.1] " MISTBORN_INTERNAL_IP
    echo
    MISTBORN_INTERNAL_IP=${MISTBORN_INTERNAL_IP:-10.3.3.1}
done
>&2 echo "Valid IP address!"


# add to bashrc
sed -i "s/MISTBORN_INTERNAL_IP.*//" ~/.bashrc
echo "MISTBORN_INTERNAL_IP=${MISTBORN_INTERNAL_IP}" | tee -a ~/.bashrc

echo
echo "MISTBORN_INTERNAL_IP is set: ${MISTBORN_INTERNAL_IP}"
echo
