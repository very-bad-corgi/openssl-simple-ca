#!/bin/bash

#
# Представлены общие методы
#

##  Метод получения / запроса пароля от л. ключа издающего УЦ 
###     Если переменные окружения от паролей определены в .env, то возьмем их
###     иначе затребуем ввод пароля
getPasswordPrivateKeyCA()
{
    echo ""
    if [ "$ENV_ENROLL_BY_CA" == "root" ] && [ ! -z "$ENV_PRIVATE_KEY_ROOT" ]; then

        echo "Pass for private key ${green}Root CA${white} taken from environment variable"
        passphrase="pass:$ENV_PRIVATE_KEY_ROOT"

    elif [ "$ENV_ENROLL_BY_CA" == "subca" ] && [ ! -z "$ENV_PRIVATE_KEY_SUBCA" ]; then
        
        echo "Pass for private key ${green}Subordinate CA${white} taken from environment variable"
        passphrase="pass:$ENV_PRIVATE_KEY_SUBCA"

    else
        read -sp "Enter your password from ${green}$ENV_ENROLL_BY_CA${white} CA: " password
        passphrase="pass:$password"
    fi
    echo ""
}

##  Метод создает копию БД в UTF8, подерживающую русские символы
createUTF8CopyDatabase()
{
    perl -pe 's/\\x([0-9A-Fa-f]{2})/chr(hex($1))/ge' ./db/$ENV_ENROLL_BY_CA/index.txt > ./db/$ENV_ENROLL_BY_CA/index_utf8.txt
}