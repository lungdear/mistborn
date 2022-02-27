#!/bin/bash

mistborn_callsubmigrations() {
    folder="$1"

    for filename in $(find ${folder} -maxdepth 1 -type f -name "*.sh")
    do
        $filename "$@"
    done

}

mistborn_add2file() {

    folder="$1"
    target_filename="$2"
    preceding_string="$3"
    target_string="$4"

    if [ "${preceding_string}" == "MISTBORN_TOP_OF_FILE" ]; then
        # put at the top of the file
        sudo sed -i "1s/^/${target_string}\n/" "${target_filename}"

    # default add to bottom of file
    elif grep -q -e "${preceding_string}" "${target_filename}"; then

        # add after given line
        sudo sed -i "/${preceding_string}/a ${target_string}" "${target_filename}"

    else
        # add to bottom of file
        echo ${target_string} | sudo tee -a ${target_filename}
    fi

    mistborn_callsubmigrations "${folder}" "${target_filename}" "${preceding_string}" "${target_string}"

}

mistborn_readfile() {
    folder="$1"
    filename="$2"

    # create file handle
    exec 5< ${filename}

    while read delimiter <&5 ; do
        read target_filename <&5
        read test_string <&5
        read preceding_string <&5
        read target_string <&5

        if [ "${delimiter}" != "###" ]; then
            echo "migration file corrupt: ${delimiter} in ${filename}"
            exec 5<&-
            exit 1;
        fi

        if [ ! -f "${target_filename}" ]; then
            echo "file does not exist: ${target_filename}"
            exec 5<&-
            exit 1;
        fi

        echo "TARGET FILENAME: ${target_filename}"
        echo "TEST STRING: ${test_string}"
        echo "PRECEDING STRING: ${preceding_string}"
        echo "TARGET STRING: ${target_string}"

        if grep -q -e "${test_string}" "${target_filename}"; then

            echo "${test_string} already in ${target_filename}"
        
        else

            echo "${test_string} not in ${target_filename}"
            echo "adding ${target_string}"

            mistborn_add2file "${folder}" "${target_filename}" "${preceding_string}" "${target_string}"
        fi
    
    done

    # close file handle
    exec 5<&-
}


mistborn_migrations() {
    folder="$1"

    echo "Folder name: ${folder}"

    for filename in $(find ${folder} -maxdepth 1 -type f -name "*.txt")
    do
        echo "file: ${filename}"
        mistborn_readfile "$folder" "$filename"
    done

}


# run migrations for all containing folders
for folder in $(find $(dirname "$0")/* -maxdepth 1 -type d -not -name ".")
do
    mistborn_migrations "$folder"
done