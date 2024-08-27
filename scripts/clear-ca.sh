#!/bin/bash

cleaning_dirs=("/ca/root"
"/ca/subca"
"/db/root"
"/db/subca"
"/user-certs-issuing-ca" 
"/user-certs-package/clients"
"/user-certs-package/entity_persons"
"/user-certs-package/servers")

echo "Do you want to cleaning following directories?"
for i in "${cleaning_dirs[@]}"; do
    echo "$i"
done
echo ""
echo "In the directory - $PWD/"
echo ""
echo "Total directories: ( ${#cleaning_dirs[@]} )"
read -p "Is this ok ? [y/N]: " -n 1 response
echo ""

# Приведение введенного ответа к нижнему регистру
response=${response,,}

if [[ "$response" == "y" ]]; then    
    echo ""
    echo "Begin cleaning your Certificate Authority"

    for i in "${cleaning_dirs[@]}"; do
        rm -rf $PWD$i/*

        echo "cleaned $i"
    done
else
    echo "Clearance cancelled"
fi

