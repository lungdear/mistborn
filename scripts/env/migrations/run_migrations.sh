#!/bin/bash

mistborn_add2file() {

    target_filename="$1"
    preceding_string="$2"
    target_string="$3"

    # default add to bottom of file

    if grep -q "${preceding_string}" "${target_filename}"; then

        sudo sed -i "s/${preceding_string}/a ${target_string}" "${target_filename}"

    else
        # add to bottom of file
        echo ${target_string} | sudo tee -a ${target_filename}
    fi

}

mistborn_readfile() {
    filename="$1"

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

        echo "TARGET FILENAME: ${target_filename}"
        echo "TEST STRING: ${test_string}"
        echo "PRECEDING STRING: ${preceding_string}"
        echo "TARGET STRING: ${target_string}"

        if grep -q "${test_string}" "${target_filename}"; then

            echo "${test_string} already in ${target_filename}"
        
        else

            echo "${test_string} not in ${target_filename}"
            echo "adding ${target_string}"

            mistborn_add2file "${target_filename}" "${preceding_string}" "${target_string}"
        fi
    
    done

    # close file handle
    exec 5<&-
}


mistborn_migrations() {
    folder="$1"

    echo "Folder name: ${folder}"

    for filename in $(find ${folder} -maxdepth 1 -type f)
    do
        echo "file: ${filename}"
        mistborn_readfile "$filename"
    done

}


# run migrations for all containing folders
for folder in $(find . -maxdepth 1 -type d -not -name ".")
do
    mistborn_migrations "$folder"
done