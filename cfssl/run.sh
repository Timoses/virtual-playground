#!/bin/bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

CSR_JSON="csr.json"

CERT_FILE="cert.pem"
KEY_FILE="cert-key.pem"
CSR_FILE="cert.csr"

ROOT_TO_INT_CONFIG="$DIR/ca/root/root-to-int-ca.json"
INT_TO_CLIENT_CONFIG="$DIR/ca/int-1/int-to-client-cert.json"


# ROOT CA
cd $DIR/ca/root
if [ ! -f $CERT_FILE ] || [ ! -f $KEY_FILE ] ; then
    echo " ========  Creating Root CA ======== "
    cfssl gencert -initca $CSR_JSON | cfssljson -bare
fi

# Intermediata CA
cd $DIR/ca/int-1
if [ ! -f $CERT_FILE ] || [ ! -f $KEY_FILE ] ; then
    echo " ======== Creating Intermediate CA ======== "
    cfssl gencert -initca $CSR_JSON | cfssljson -bare
    cfssl sign -ca $DIR/ca/root/$CERT_FILE -ca-key $DIR/ca/root/$KEY_FILE \
        -config $ROOT_TO_INT_CONFIG $CSR_FILE | cfssljson -bare
fi

# End certificates
for dir in `find $DIR/certs/* -type d` ; do
    echo " ======== Creating certificate for $(basename $dir) ======== "
    cd $dir
    cfssl gencert -ca $DIR/ca/int-1/$CERT_FILE -ca-key $DIR/ca/int-1/$KEY_FILE -config $INT_TO_CLIENT_CONFIG $CSR_JSON | cfssljson -bare
done

