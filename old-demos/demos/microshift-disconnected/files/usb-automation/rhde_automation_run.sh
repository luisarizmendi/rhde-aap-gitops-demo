#!/bin/bash

## CHECK VARS

if [ $# -ne 2 ]; then
    echo "Script was not run with two arguments."
    exit -1
fi

##################

SCRIPTS_TAR_FILE=$1
SCRIPTS_DIR=$2

SCRIPTS_TEMP_DIR="/tmp/rhde-automation-scripts"



echo "Creating directory ${SCRIPTS_TEMP_DIR}"
mkdir -p ${SCRIPTS_TEMP_DIR}




echo "Decompressing file ${SCRIPTS_TAR_FILE}"
tar zxvf ${SCRIPTS_TAR_FILE} -C ${SCRIPTS_TEMP_DIR}

for i in $(find ${SCRIPTS_TEMP_DIR}/${SCRIPTS_DIR} -type f -name "*.sh"); do
        chmod +x $i 
        echo "Running script $i ..."
        bash $i 
        # Check if the script was successful
        if [ $? -eq 0 ]; then
                echo "Script $i successful"
        else
                echo "ERROR: Script $1 failed"

                echo "Removing directory ${SCRIPTS_TEMP_DIR}"
                rm -rf ${SCRIPTS_TEMP_DIR}

                exit 1
        fi

done



echo "Removing directory ${SCRIPTS_TEMP_DIR}"
rm -rf ${SCRIPTS_TEMP_DIR}


exit 0
