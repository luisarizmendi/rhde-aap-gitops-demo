#!/bin/bash


##### CHECK VARS

if [ $# -ne 3 ]; then
    echo "Script was not run with three arguments."
    exit -1
fi

# Define variables
TARGET_FILE=$1
SIGNATURE_FILE=$2
PUBLIC_KEY=$3



if [ -f "${SIGNATURE_FILE}" ]; then
    echo "Signature ${SIGNATURE_FILE} exist!"

    if [ -f "${TARGET_FILE}" ]; then
        echo "File ${TARGET_FILE} exist!"

    else 
        echo "File ${TARGET_FILE} not found!"
        exit 2
    fi
else 
    echo "ERROR: Signature ${SIGNATURE_FILE} not found!"
    exit 1
fi





# Create a tar archive of the TARGET_FILE

# Verify the signature
openssl dgst -sha256 -verify "$PUBLIC_KEY" -signature "$SIGNATURE_FILE" "${TARGET_FILE}"

# Check the exit code to determine verification success or failure
if [ $? -eq 0 ]; then
    echo "Signature is valid. Content has not been tampered with."
else
    echo "Signature verification failed. Content may have been tampered with."
fi


exit 0


