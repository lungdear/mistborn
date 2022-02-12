#!/bin/bash

# INPUT domain
while [ -z "${MISTBORN_BASE_DOMAIN}" ]; do
    echo
    echo "(Mistborn) The domain may container alphanumeric characters and periods"
    read -p "(Mistborn) Set base domain: [mistborn]" MISTBORN_BASE_DOMAIN
    echo
    MISTBORN_BASE_DOMAIN=${MISTBORN_BASE_DOMAIN:-mistborn}

    if [[ ${MISTBORN_BASE_DOMAIN} =~ ^[A-Za-z0-9.]+$ ]]; then
    # it matches
        echo "(Mistborn) Domain is accepted"
    else
        unset MISTBORN_BASE_DOMAIN
        echo "(Mistborn) Try again"
    fi

done

echo
echo "MISTBORN_BASE_DOMAIN is set: ${MISTBORN_BASE_DOMAIN}"
echo
