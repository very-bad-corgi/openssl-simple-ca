#!/bin/bash

source .env
source ./scripts/shared-functions.sh

getPasswordPrivateKeyCA

if [ "$1" == "root" ]; then

    ./openssl ca -gencrl -config ./profiles/root.conf -out ./ca/root/root.crl \
    -passin $passphrase
 
elif [ "$1" == "subca" ]; then 

    ./openssl ca -gencrl -config ./profiles/subca.conf -out ./ca/subca/subca.crl \
    -passin $passphrase

fi