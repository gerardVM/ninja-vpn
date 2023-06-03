#!/bin/bash

case $(cat ./users/${1}.yaml | yq -r .action) in
    deploy)
        make vpn-deploy USER=${1}
        ;;
    destroy)
        make vpn-destroy USER=${1}
        ;;
    *)
        echo "Usage: $0 {deploy|destroy}"
        exit 1
esac