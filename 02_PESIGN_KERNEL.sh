#!/bin/bash -xe

ROOT_CA_P12="rootCA.p12"
ROOT_CA_PASSWORD="password"
ROOT_CA_NICKNAME="MasterRootCA" # The name we gave it during export

NSS_DB_DIR="./nssdb"

# Existing kernel binary to (re)sign
KERNEL=/boot/vmlinuz-$(uname -r)
KERNEL_UNSIGNED="vmlinuz.unsigned"
KERNEL_SIGNED="vmlinuz.signed"

# Create a temporary Network Security Services (NSS) database
rm -rf ${NSS_DB_DIR}
mkdir -p ${NSS_DB_DIR}
certutil -N -d ${NSS_DB_DIR} --empty-password

# Import the Root CA's PKCS#12 archive into the NSS database
pk12util -i ${ROOT_CA_P12} -d ${NSS_DB_DIR} -W ${ROOT_CA_PASSWORD}

# Optionally, remove the original kernel's existing signature
if false
then
pesign -n ${NSS_DB_DIR} \
    -c ${ROOT_CA_NICKNAME} \
    -r -u 0 \
    -i ${KERNEL} \
    -o ${KERNEL_UNSIGNED}
else
    KERNEL_UNSIGNED=${KERNEL}
fi

# Sign the kernel binary
pesign -n "$NSS_DB_DIR" \
    -c ${ROOT_CA_NICKNAME} \
    -s \
    -i ${KERNEL_UNSIGNED} \
    -o ${KERNEL_SIGNED} \

# Check the signature (with pesign)
pesign -n ${NSS_DB_DIR} -v -i ${KERNEL_SIGNED}

# Check the signature (with sbverity)
sbverify --list ${KERNEL_SIGNED}
sbverify --cert rootCA.crt ${KERNEL_SIGNED}
