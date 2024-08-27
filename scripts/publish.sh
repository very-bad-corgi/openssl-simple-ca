#!/bin/bash

source ./publish-by-ftp.hosts.sh

list_crl=( ./ca/root/root.crl )
list_certs=( ./ca/root/root.crt )

if [[ "$ENV_ENROLL_BY_CA" == *"subca"* ]]; then

    list_crl+=( ./ca/subca/subca.crl )
    list_certs+=( ./ca/subca/subca.crt )

fi

for server in "${!ftp_servers_[@]}"; do

    login=$( echo "${ftp_servers_[$server]}" | awk -F':' '{ print $1 }' )
    password=$( echo "${ftp_servers_[$server]}" | awk -F':' '{ print $2 }' )

    echo "Send files to FTP-server: $server"

    if [ "$1" == "certificates" ]; then 

        ncftpput -u "$login" -p "$password" -v "$server" "/$target_directory_" \
            ${list_certs[@]}

    elif [ "$1" == "crl" ]; then 

        ncftpput -u "$login" -p "$password" -v "$server" "/$target_directory_" \
            ${list_crl[@]}
    fi
done
