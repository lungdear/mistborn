#!/bin/bash

folder="$1" 
target_filename="$2" 
preceding_string="$3" 
target_string="$4" 

TMP_FILE="$(mktemp)"

echo "submigrations: live rule push"

sudo iptables-save | tee ${TMP_FILE}

if [ "${preceding_string}" == "MISTBORN_TOP_OF_FILE" ]; then

    # top
    sudo sed -i "1s/^/${target_string}\n/" "${TMP_FILE}"

elif grep -q -e "${preceding_string}" "${TMP_FILE}"; then

    # after
    sudo sed -i "/${preceding_string}/a ${target_string}" "${TMP_FILE}"

else
    # bottom
    echo ${target_string} | sudo tee -a ${TMP_FILE}
fi

sudo iptables-restore < ${TMP_FILE}
rm -f ${TMP_FILE}