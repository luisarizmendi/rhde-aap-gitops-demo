#!/bin/bash

set -x

if rpm -q libreswan &> /dev/null; then

    cp /var/opt/ipsec.secrets /etc/ipsec.secrets

    systemctl enable --now ipsec
    systemctl restart ipsec
fi
