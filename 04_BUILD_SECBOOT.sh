#!/bin/bash -xe

EFI_SIGNER="./sign-files.sh"

ROOTCA_P12=rootCA.p12
ROOTCA_P12_PASSWORD=rootCA.password

SB_UNSIGNED="localhost/secureboot:unsigned"
SB_PREPARED="localhost/secureboot:prepared"
SB_SIGNED="localhost/secureboot:signed"

IMG_SIGNED="secureboot-signed.img"


AIB_DIR=../automotive-image-builder
AIB=${AIB_DIR}/bin/aib
#AIB=/usr/bin/aib

DISTRO=autosd10
TARGET=qemu
IMAGE_MANIFEST=secureboot.aib.yml

${AIB} build --build-dir _build-dir --verbose \
        --target ${TARGET} --distro ${DISTRO} \
        ${IMAGE_MANIFEST} ${SB_UNSIGNED}

# Generate a throwaway key (no password) and prepare for resealing with it
openssl genpkey -algorithm ed25519 -outform PEM -out private.pem

NSS_DB_DIR=./nssdb

# Create a temporary NSS database
if [ ! -d ${NSS_DB_DIR} ]
then
        mkdir -p ${NSS_DB_DIR}
        certutil -N -d ${NSS_DB_DIR} --empty-password
fi

if [ ! -f builder.done ]
then
	${AIB} build-builder --distro autosd10
	touch builder.done
fi

${AIB} prepare-reseal --key=private.pem ${SB_UNSIGNED} ${SB_PREPARED}

# Extract the EFI files to sign
${AIB} extract-for-signing ${SB_PREPARED} to-sign

# Sign the EFI files
${EFI_SIGNER} --nssdb ${NSS_DB_DIR} --certificates ${ROOTCA_P12} --password-file ${ROOTCA_P12_PASSWORD} to-sign/efi/*

# Inject the signed EFI files and reseal
${AIB} inject-signed --reseal-with-key=private.pem ${SB_PREPARED} to-sign ${SB_SIGNED}

${AIB} to-disk-image ${SB_SIGNED} ${IMG_SIGNED}
