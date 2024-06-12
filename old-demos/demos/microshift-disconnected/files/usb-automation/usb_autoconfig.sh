#!/bin/bash

# Log file path
log_file="/var/log/usb_check.log"

# Redirect stdout and stderr to the log file
exec > "$log_file" 2>&1

sleep 3

############### VARS ####################

RHDE_DIR="rhde"
RHDE_ENCRYPTED_FILE="rhde_encrypted.tar"
RHDE_AUTOMATION_DIR="rhde-automation"
RHDE_AUTOMATION_TAR="rhde-automation.tar.gz"
RHDE_AUTOMATION_RUN="/usr/bin/rhde_automation_run.sh"

ENCRYPTION_KEY="/usr/share/rhde_automation_encryption_key"

TEMP_DIR="/tmp/usb-autoconfigure"

SIGNATURE_VERIFICATION_SCRIPT="/usr/bin/signature_verification_script.sh"

USB_DEVICE=$(cat /tmp/last-usb)

SIGNATURE_FILE="rhde-automation-signature.sha256"
PUBLIC_KEY="/usr/share/rhde-automation-pub.pem"

######################################

rm -f $TEMP_DIR/* 2>/dev/null
mkdir -p $TEMP_DIR/mnt


echo "Mounting ${USB_DEVICE}1 into ${TEMP_DIR}/mnt"
# Mount the filesystem using systemd-mount
mount ${USB_DEVICE}1 ${TEMP_DIR}/mnt

# Check if the mount was successful
if [ $? -eq 0 ]; then
    echo "Mount successful"
else
    echo "Mount failed"
    exit 1
fi



RUN_SIGNATURE=false
RUN_DECRYPT=false

# Check if the rhde directory exists on the USB device
if [ -d "${TEMP_DIR}/mnt/${RHDE_DIR}" ]; then
    echo "Directory ${TEMP_DIR}/mnt/${RHDE_DIR} exist!"
    RUN_SIGNATURE=true
else
    echo "Directory ${TEMP_DIR}/mnt/${RHDE_DIR} not found, looking for $RHDE_ENCRYPTED_FILE encrypted file"
    if [ -f "${TEMP_DIR}/mnt/${RHDE_ENCRYPTED_FILE}" ]; then

        RUN_DECRYPT=true

        RUN_SIGNATURE=true
    else
        echo "Neither ${TEMP_DIR}/mnt/${RHDE_DIR} directory nor $RHDE_ENCRYPTED_FILE encrypted file found"
        umount $TEMP_DIR/mnt
        exit 2
    fi
fi



if $RUN_DECRYPT; then
    echo "Copying ${TEMP_DIR}/mnt/${RHDE_ENCRYPTED_FILE} into ${TEMP_DIR}/${RHDE_ENCRYPTED_FILE}"
    cp ${TEMP_DIR}/mnt/${RHDE_ENCRYPTED_FILE} ${TEMP_DIR}/${RHDE_ENCRYPTED_FILE}

    echo "Decrypting file ${TEMP_DIR}/${RHDE_ENCRYPTED_FILE}"
    openssl enc -d -aes-256-cbc -in ${TEMP_DIR}/${RHDE_ENCRYPTED_FILE} -out ${TEMP_DIR}/rhde.tar -pass file:${ENCRYPTION_KEY} -pbkdf2
    if [ $? -eq 0 ]; then
        echo "Decryption successful"
    else
        echo "ERROR: Decryption failed"
        umount $TEMP_DIR/mnt
        exit 5
    fi
    echo "Uncompressing files"
    tar xvf ${TEMP_DIR}/rhde.tar -C ${TEMP_DIR}
else
    # just copy rhde directory
    echo "Copying ${TEMP_DIR}/mnt/${RHDE_DIR} into ${TEMP_DIR}/${RHDE_DIR}"
    cp -r ${TEMP_DIR}/mnt/${RHDE_DIR} ${TEMP_DIR}/${RHDE_DIR}
fi


if $RUN_SIGNATURE; then
    chmod +x ${SIGNATURE_VERIFICATION_SCRIPT}
    ## script <dir> <signature file> <public key>
    ${SIGNATURE_VERIFICATION_SCRIPT} ${TEMP_DIR}/${RHDE_DIR}/${RHDE_AUTOMATION_TAR} ${TEMP_DIR}/${RHDE_DIR}/${SIGNATURE_FILE} ${PUBLIC_KEY}

    if [ $? -eq 0 ]; then
        echo "Signature verification succeded"
        echo "Extracting automations on ${TEMP_DIR}/${RHDE_DIR}/${RHDE_AUTOMATION_TAR} from ${RHDE_AUTOMATION_DIR}"
       # script <tar location> <directory in the tar with the scripts> 
        ${RHDE_AUTOMATION_RUN} ${TEMP_DIR}/${RHDE_DIR}/${RHDE_AUTOMATION_TAR} ${RHDE_AUTOMATION_DIR}

        # Check if the automation script was successful
        if [ $? -eq 0 ]; then
            echo "Automation successful"
        else
            echo "Automation failed"
            echo "Removing directory ${TEMP_DIR}/${RHDE_DIR}"
            rm -rf ${TEMP_DIR}/${RHDE_DIR}
            exit 4
        fi


    else
        echo "Error: Signature verification failed"
        umount $TEMP_DIR/mnt
        echo "Removing directory ${TEMP_DIR}/${RHDE_DIR}"
        rm -rf ${TEMP_DIR}/${RHDE_DIR}
        exit 3
    fi
else
    umount $TEMP_DIR/mnt
    echo "Removing directory ${TEMP_DIR}/${RHDE_DIR}"
    rm -rf ${TEMP_DIR}/${RHDE_DIR}
    exit 2
fi



echo "Removing directory ${TEMP_DIR}/${RHDE_DIR}"
rm -rf ${TEMP_DIR}/${RHDE_DIR}

# Unmount the filesystem using systemd-umount
umount ${TEMP_DIR}/mnt

# Check if the umount was successful
if [ $? -eq 0 ]; then
    echo "Unmount successful"
else
    echo "Unmount failed"
    exit 1
fi


exit 0