#!/bin/bash

source .env

mkdir -p user-requests \
         user-certs-issuing-ca \
         user-certs-package/clients \
         user-certs-package/servers

### Root CA
#### Генерируем всегда
if [ "$1" == "root" ] || [[ "$1" == *"subca"* ]]; then

    if [ -e "./ca/root/root.key" ]; then
        echo ""
        echo "Root CA exists!"
        exit 1
    fi

    mkdir -p ca/root db/root

    touch ./db/root/index.txt                        # Database for issuing certificates
    echo "010000000000000000" > ./db/root/serial     # First serial number user certificate
    echo "010000000000000000" > ./db/root/crlnumber  # First serial number CRL
    
    # Определим переменную окружения, в которой зафиксируем УЦ, издающий конечных участников
    sed -i 's/ENV_ENROLL_BY_CA=\(.*\)/ENV_ENROLL_BY_CA=root/' ./.env

    if [ -z "$ENV_PRIVATE_KEY_ROOT" ]; then
        echo "Private key ${green}Root CA${white} encryption using a password"
        read -sp "Enter your password: " password
    else
        password="$ENV_PRIVATE_KEY_ROOT"
    fi
    ./openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -outform PEM -out ./ca/root/root.key \
    -pass pass:$password -aes256

    # Корневой сертификат издается на 10 лет
    ./openssl req -x509  -new -utf8 -key ./ca/root/root.key -out ./ca/root/root.crt -days 3650 \
    -config ./profiles/root.conf -extensions v3_root \
    -passin pass:$password
fi

### Subordinate CA 
#### Опционально
if [[ "$1" == *"subca"* ]]; then 

    if [ -e "./ca/subca/subca.key" ]; then
        echo ""
        echo "Subordinate CA exists!"
        exit 1
    fi

    mkdir -p ca/subca db/subca

    touch ./db/subca/index.txt                          # Database for issuing certificates
    echo "01000000000000000000" > ./db/subca/serial     # First serial number user certificate
    echo "01000000000000000000" > ./db/subca/crlnumber  # First serial number CRL

    # Определим переменную окружения, в которой зафиксируем УЦ, издающий конечных участников
    sed -i 's/ENV_ENROLL_BY_CA=\(.*\)/ENV_ENROLL_BY_CA=subca/' ./.env
    
    if [ -z "$ENV_PRIVATE_KEY_SUBCA" ]; then
        echo ""
        echo "Private key ${green}Subordinate CA${white} encryption using a password"
        read -sp "Enter your password: " password
    else
        password="$ENV_PRIVATE_KEY_SUBCA"
        password_root="$ENV_PRIVATE_KEY_ROOT"
    fi

    ./openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -outform PEM -out ./ca/subca/subca.key \
    -pass pass:$password -aes256

    ./openssl req -new -utf8  -key ./ca/subca/subca.key -out ./ca/subca/subca.csr \
    -config ./profiles/subca.conf -extensions v3_subca \
    -passin pass:$password

    # Подчиненный сертификат издается на 10 лет
    ./openssl x509 -req  -in ./ca/subca/subca.csr -CA ./ca/root/root.crt -CAkey ./ca/root/root.key \
    -out ./ca/subca/subca.crt -days 3649 -extfile ./profiles/root.conf -extensions v3_subca \
    -passin pass:$password_root

fi