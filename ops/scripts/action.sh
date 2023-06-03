#!/bin/bash

case $(cat ./users/${1}.yaml | yq -r .action) in
    deploy)
        make vpn-deploy USER=${1}
        ;;
    destroy)
        make vpn-destroy USER=${1}
        ;;
    init)
        make tf-init USER=${1}
        ;;
    validate)
        make tf-validate USER=${1}
        ;;
    plan)
        make tf-plan USER=${1}
        ;;
    *)
        echo "Usage: $0 {deploy|destroy}"
        exit 1
esac