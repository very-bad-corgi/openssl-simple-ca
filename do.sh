#!/bin/bash

source .env

_do_autocomplete() {
    local cur prev opts

    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    if [ $COMP_CWORD -eq 1 ]; then
        opts="enroll revoke issuing-crl init-ca clear-ca publish-by-ftp version"
    fi

    if [ $COMP_CWORD -eq 2 ]; then
        case "$prev" in
            enroll)
                opts="client server"
                ;;
            revoke)
                opts="user subca"
                ;;
            init-ca)
                opts="root subca+root"
                ;;
            issuing-crl)
                opts="root subca"
                ;;
            publish-by-ftp)
                opts="certificates crl"
                ;;
            *)
                opts=""
                ;;
        esac
    fi

    if [ $COMP_CWORD -eq 3 ]; then
        case "$prev" in
            ca)
                opts="root subca"
                ;;
            client)
                opts="one-key-file-gen by-request"
                ;;
            server)
                opts="one-key-file-gen by-request"
                ;;
            *)
                opts=""
                ;;
        esac
    fi

    if [ $COMP_CWORD -eq 4 ]; then
        list=$(find ./user-requests -name '*.req' -type f -exec basename {} \;)

        case "$prev" in
            by-request)
                opts="all ${list[@]}"
                ;;
            one-key-file-gen)
                opts="encrypt-by-aes256"
                ;;
            *)
                opts=""
                ;;
        esac
    fi

    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
    return 0
}

complete -F _do_autocomplete do.sh

case "$1" in
    enroll)
        echo "You chose ${green}enroll${white} with subactions: ${orange}$2${white} ${orange}$3${white} ${orange}$4${white}"
        if [[ $3 == "by-request" && "$4" == "all" ]]; then

            list=$(ls user-requests | grep 'req')

            declare failed_requests
            count_all=0 ; count_success=0
            for i in $list; do
                ((++count_all))
                ./scripts/enroll.sh $2 $3 $i
                if [ $? -ne 0 ]; then
                    failed_requests+=("$i")
                else 
                    ((++count_success))
                fi
            done

            echo ""
            echo "All iterations count - ${orange}$count_all${white}, success - ${green}$count_success${white}, failed - ${red}${#failed_requests[@]}${white}"
            echo "List failed files: ${orange}${failed_requests[@]}${white}"
        else
            ./scripts/enroll.sh $2 $3 $4
        fi
        
        ;;
    revoke)
        echo "You chose ${green}revoke${white} with subactions: ${orange}$2${white} ${l_green}$3${white}" 
        ./scripts/revoke.sh $2 $3
        ;;
    init-ca)
        echo "You chose ${green}init-ca${white} with subactions: ${orange}$2${white}" 
        ./scripts/init-ca.sh $2
        ;;
    issuing-crl)
        echo "You chose ${green}issuing-crl${white} with subactions: ${orange}$2${white}" 
        ./scripts/issuing-crl.sh $2
        ;;
    publish-by-ftp)
        echo "You chose ${green}publish-by-ftp${white} with subactions: ${orange}$2${white}" 
        ./scripts/publish.sh $2
        ;;
    clear-ca)
        echo "You chose ${green}clear-ca${white}" 
        ./scripts/clear-ca.sh
        ;;
    version)
        echo "You chose ${green}version${white}" 
        ./openssl version
        ;;
    *)
        echo "Usage: $0 {enroll|revoke|init-ca|issuing-crl|clear-ca|version} {subactions} .."
        ;;
esac
