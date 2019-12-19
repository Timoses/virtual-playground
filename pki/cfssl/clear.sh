#!/bin/bash

read -p "Delete all certs, keys and csr files? [y/Y] " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
    DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

    find $DIR -name "*.pem" -type f -delete
    find $DIR -name "*.csr" -type f -delete
fi



