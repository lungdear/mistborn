#!/bin/bash

set -e

MISTBORN_HOME="/opt/mistborn"

# check that pwgen exists
if ! [ -x "$(command -v pwgen)" ]; then
    echo "Installing pwgen"
    sudo apt-get install -y pwgen
fi

echo "Mistborn service wrapper: Starting...."

SERVICES="$1"
shift

IFS=','
read -ra SERVICES_ARRAY <<< "${SERVICES}"
for SERVICE in "${SERVICES_ARRAY[@]}"; do
    MISTBORN_SERVICE_FILE=${MISTBORN_HOME}/.envs/.production/.${SERVICE}
    MISTBORN_SERVICE_INIT=${MISTBORN_HOME}/scripts/services/${SERVICE}/init.sh

    # check and create file if needed
    ${MISTBORN_HOME}/scripts/env/check_env_file.sh ${SERVICE}

    # read in variables
    set -a
    #source ${MISTBORN_HOME}/.env
    
    VAR_FILE="$(mktemp)"
    cat ${MISTBORN_HOME}/.env | egrep -v "(^[[:space:]]*#.*|^[[:space:]]*$|.*\`.*)" | tee ${VAR_FILE}
    . ${VAR_FILE}

    if [[ -f "${MISTBORN_SERVICE_FILE}" ]]; then
        echo "Loading service variables"
        #source ${MISTBORN_SERVICE_FILE}
        
        VAR_FILE="$(mktemp)"
        cat ${MISTBORN_SERVICE_FILE} | egrep -v "(^[[:space:]]*#.*|^[[:space:]]*$|.*\`.*)" | tee ${VAR_FILE}
        . ${VAR_FILE}
    else
        echo "No service variables to load. Proceeding."
    fi
    set +a

    # init script
    if [[ -f "${MISTBORN_SERVICE_INIT}" ]]; then
        echo "Running init script"
        ${MISTBORN_SERVICE_INIT}
    else
        echo "No init script. Proceeding."
    fi
done

# check that netcat exists
if ! [ -x "$(command -v nc)" ]; then
    echo "Installing netcat"
    sudo apt-get install -y netcat
fi

# ensure base is up and listening
echo "Checking that Mistborn-base has finished starting up..."

while ! nc -z ${MISTBORN_BIND_IP} 5000; do
    WAIT_TIME=$((5 + $RANDOM % 15))
    echo "Waiting ${WAIT_TIME} seconds for Mistborn-base..."
    sleep ${WAIT_TIME}
done

echo "Mistborn-base is running"

exec "$@"
