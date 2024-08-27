#!/bin/bash

source .env
source ./scripts/shared-functions.sh

#set -e

profile_v3_ext="v3_$1"
issuing_ca_dir=user-certs-issuing-ca/
cert_serial_number=$( tail ./db/$ENV_ENROLL_BY_CA/serial )
package_dir=user-certs-package/${1}s/$cert_serial_number
cert_request_file=""


echo "Creating directory: $package_dir"
mkdir -p $PWD/$package_dir

if [ "$2" == "one-key-file-gen" ]; then

    echo "Generate key"
    if [ "$3" == "encrypt-by-aes256" ]; then 
        echo "With private key encryption using a password"
        read -sp "Enter your password: " password
        need_encrypt_by_pass="-pass pass:$password -aes256"
        pass_for_request="-passin pass:$password"

        echo "$password" > $package_dir/pass.txt
    fi
    
    ./openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -outform PEM -out ./$package_dir/key.pem \
        $need_encrypt_by_pass

    echo "Generate certificate request"
    ./openssl req -new -utf8 -key ./$package_dir/key.pem -out ./$package_dir/request.csr \
        -config ./profiles/default-users/$1.conf \
        $pass_for_request

    cert_request_file=$package_dir/request.csr

elif [ "$2" == "by-request" ]; then 

    cert_request_file=user-requests/$3

fi

getPasswordPrivateKeyCA

### Издание сертификата
./openssl ca -batch -config ./profiles/$ENV_ENROLL_BY_CA.conf -extensions $profile_v3_ext \
-in "./$cert_request_file" -out ./$package_dir/parsed-cert.pem \
-days 1095 -passin $passphrase

if [ "$2" == "by-request" ]; then 
    mv ./$cert_request_file ./$package_dir/
fi

./openssl x509 -in ./$package_dir/parsed-cert.pem -out ./$package_dir/cert.pem

###
###     Optional - convert issued certificate to UTF8
###    создаем копию БД, подерживающую русские символы
###
./openssl x509 -in ./$issuing_ca_dir/$cert_serial_number.pem -text -nameopt utf8 -out ./$issuing_ca_dir/$cert_serial_number.pem
./openssl x509 -in ./$package_dir/parsed-cert.pem -text -nameopt utf8 -out ./$package_dir/parsed-cert.pem

createUTF8CopyDatabase