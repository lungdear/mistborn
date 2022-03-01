#!/bin/bash

ENV_FILE=/opt/mistborn/.env

export $(grep 'MISTBORN_BASE_DOMAIN' ${ENV_FILE} | xargs)

# check that curl exists
if ! [ -x "$(command -v curl)" ]; then
    echo "Installing curl"
    sudo apt-get install -y curl
fi

HTTPD="000"
until [ "$HTTPD" == "200" ]; do
    HTTPD=$(curl -k -A "Web Check" -sL --connect-timeout 3 -w "%{http_code}\n" "http://nextcloud.${MISTBORN_BASE_DOMAIN}" -o /dev/null)
    echo "Waiting for Nextcloud to start... ${HTTPD} at nextcloud.${MISTBORN_BASE_DOMAIN}"
    sleep 10 
done

echo "Nextcloud is running! Setting config.php variables."

docker-compose -f /opt/mistborn/extra/nextcloud.yml exec -T nextcloud su -p www-data -s /bin/sh -c "php /var/www/html/occ config:system:set verify_peer_off --value=true"
docker-compose -f /opt/mistborn/extra/nextcloud.yml exec -T nextcloud su -p www-data -s /bin/sh -c "php /var/www/html/occ config:system:set allow_local_remote_servers --value=true"
