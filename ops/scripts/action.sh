#!/bin/bash

case $(cat ./users/${1}.yaml | yq -r .action) in
    deploy)
        make vpn-deploy USER=${1}
        ;;
    destroy)
        make vpn-destroy USER=${1}
        ;;
    init)
        make set_user USER=${1}
        make tf-init
        ;;
    validate)
        make set_user USER=${1}
        make tf-validate
        ;;
    plan)
        make set_user USER=${1}
        make tf-init
        make tf-plan
        ;;
    *)
        echo "Usage: $0 {deploy|destroy|init|validate|plan}"
        exit 1
esac