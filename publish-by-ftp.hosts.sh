#!/bin/bash

target_directory_=$( basename "$PWD" )

declare -A ftp_servers_

# Инициализируем список FTP-серверов, на которые должна производиться 
#   рассылка сертификатов / CRL УЦ
ftp_servers_=(
    ["127.0.0.1"]="ftpuser:ftppassword"
    ["192.168.15.12"]="ftpuser:ftppassword"
)