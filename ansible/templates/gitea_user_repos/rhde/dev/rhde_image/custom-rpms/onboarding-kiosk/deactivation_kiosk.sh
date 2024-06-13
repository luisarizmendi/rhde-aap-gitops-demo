#!/bin/bash

activation_file="/var/tmp/activation_done"

perform_actions() {

    sleep 2
    
    systemctl isolate multi-user.target
    systemctl set-default multi-user.target

    systemctl stop gdm.service
    systemctl disable gdm.service

    systemctl stop deactivation-kiosk.service 
    systemctl disable deactivation-kiosk.service      
}


while true
do
    if [ -f "$activation_file" ]; then
        perform_actions
        exit 0
    fi
    sleep 2
done