#!/bin/bash

set -e

folder="$1" 
target_filename="$2" 
preceding_string="$3" 
target_string="$4" 

TMP_FILE="$(mktemp)"

echo "submigrations: live rule push"

if [ "${target_filename}" == "/etc/iptables/rules.v4" ]; then

    sudo iptables-save > ${TMP_FILE}

    if [ "${preceding_string}" == "MISTBORN_TOP_OF_FILE" ]; then

        # top
        sed -i "1s/^/${target_string}\n/" "${TMP_FILE}"

    elif grep -q -e "${preceding_string}" "${TMP_FILE}"; then

        # after
        sed -i "s/.*${preceding_string}.*/&\n${target_string}" "${TMP_FILE}"

    else
        # bottom
        echo ${target_string} >> ${TMP_FILE}
    fi

    sudo iptables-restore < ${TMP_FILE}
    rm -f ${TMP_FILE}

fi
