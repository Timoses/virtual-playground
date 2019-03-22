#!/bin/bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SCRIPT=$(basename $0)

CSR_JSON="csr.json"

ROOT_TO_INT_CONFIG="$DIR/ca/root/root-to-int-ca.json"
INT_TO_CLIENT_CONFIG="$DIR/ca/int-1/int-to-client-cert.json"
CA_CONFIG_FILE="$DIR/ca/ca-config.json"

if [ -z "$GOPATH" ] ; then
    GOPATH=~/go
fi

CFSSL=$GOPATH/bin/cfssl
CFSSLJSON=$GOPATH/bin/cfssljson

if [ ! -f $CFSSL ] ; then
    echo " ... Missing cfssl -> Loading ... "
    go get -u github.com/cloudflare/cfssl/cmd/cfssl
fi
if [ ! -f $CFSSLJSON ] ; then
    echo " ... Missing cfssljson -> Loading ... "
    go get -u github.com/cloudflare/cfssl/cmd/cfssljson
fi


function print_usage() {
    case "$1" in
        bundle)
            echo "Usage: $SCRIPT bundle TARGET CERTDIRECTORY"
            echo
            echo "Targets:"
            echo "  haproxy"
            ;;
        *)
            echo "Usage: $SCRIPT COMMAND"
            echo
            echo "Commands:"
            echo "  init"
            echo "  bundle"
            ;;
    esac
}

function init() {
    # ROOT CA
    cd $DIR/ca/root
    BASE=$(basename `pwd`)
    ROOT_CERT_FILE="$(pwd)/$BASE.pem"
    ROOT_KEY_FILE="$(pwd)/$BASE-key.pem"
    if [ ! -f $ROOT_CERT_FILE ] || [ ! -f $ROOT_KEY_FILE ] ; then
        echo " ========  Creating Root CA ======== "
        $CFSSL gencert -initca $CSR_JSON | $CFSSLJSON -bare $BASE
    fi

    # Intermediata CA
    cd $DIR/ca/int-1
    BASE=$(basename `pwd`)
    INT_CERT_FILE="$(pwd)/$BASE.pem"
    INT_KEY_FILE="$(pwd)/$BASE-key.pem"
    INT_CSR_FILE="$(pwd)/$BASE.csr"
    if [ ! -f $INT_CERT_FILE ] || [ ! -f $INT_KEY_FILE ] ; then
        echo " ======== Creating Intermediate CA ======== "
        cfssl gencert -initca $CSR_JSON | cfssljson -bare $BASE
        echo $ROOT_TO_INT_CONFIG
        cat $ROOT_TO_INT_CONFIG
        $CFSSL sign -ca $ROOT_CERT_FILE -ca-key $ROOT_KEY_FILE -config $CA_CONFIG_FILE -profile 'intermediate' $INT_CSR_FILE | $CFSSLJSON -bare $BASE
    fi

    # End certificates
    for dir in `find $DIR/certs/* -type d` ; do
        echo " ======== Creating certificate for $(basename $dir) ======== "
        cd $dir
        BASE=$(basename `pwd`)
        CERT_FILE="$(pwd)/$BASE.pem"
        KEY_FILE="$(pwd)/$BASE-key.pem"
        if [ ! -f $CERT_FILE ] || [ ! -f $KEY_FILE ] ; then
            $CFSSL gencert -ca $INT_CERT_FILE -ca-key $INT_KEY_FILE -config $INT_TO_CLIENT_CONFIG $CSR_JSON | $CFSSLJSON -bare $BASE
        fi
    done
}

function bundle()
{
    if [[ $# -lt 2 ]] ; then
        print_usage "bundle"
        exit 0
    fi

    case "$1" in
        haproxy)
            BASE=$(basename $2)
            cat $DIR/$2/$BASE.pem $DIR/ca/int-1/int-1.pem $DIR/ca/root/root.pem $DIR/$2/$BASE-key.pem
            ;;
    esac
}


if [[ $# -eq 0 ]] ; then
    print_usage
    exit 0
fi

case "$1" in
    init)
        init
        ;;
    bundle)
        bundle $2 $3
        ;;
    *)
        print_usage
        ;;
esac



