#!/bin/bash

source .env
source ./scripts/shared-functions.sh

if [ "$1" == "user" ]; then

    getPasswordPrivateKeyCA

    revoked_certificate=$2.pem

    # Производим отзыв сертификата с причиной озыва по умолчанию - unspecified
    ## добавление причины отзыва сформирует нам CRL версии 2
    ./openssl ca -config ./profiles/$ENV_ENROLL_BY_CA.conf -revoke ./user-certs-issuing-ca/$revoked_certificate \
    -crl_reason unspecified -passin $passphrase

    # Издадим актуальный CRL
    ./do.sh issuing-crl $ENV_ENROLL_BY_CA

elif [ "$1" == "subca" ]; then

echo ""

fi

createUTF8CopyDatabase