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
    
    if ipaddress.ip_network("$1").subnet_of(ipaddress.ip_network('10.0.0.0/8')):
        #print('valid address')
        sys.exit(0)
    
    #print('invalid address')
    sys.exit(-1)

except Exception as e:
    sys.exit(-1)

END
}

MISTBORN_SERVER_IP="0.0.0.0"
until valid_server_ip "${MISTBORN_SERVER_IP}"; do

    >&2 echo "(Mistborn) Enter a valid IP address in 10.0.0.0/8"
    read -p "(Mistborn) Set server IP: [10.2.3.1] " MISTBORN_SERVER_IP
    echo
    MISTBORN_SERVER_IP=${MISTBORN_SERVER_IP:-10.2.3.1}
done
>&2 echo "Valid IP address!"


echo
echo "MISTBORN_SERVER_IP is set: ${MISTBORN_SERVER_IP}"
echo
