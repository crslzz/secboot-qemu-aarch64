#!/bin/bash -xe

PASSWORD="password"
GUID=$(uuidgen)

echo "${PASSWORD}" > rootCA.password

QEMU_VARS="QEMU_VARS.fd"
QEMU_VARS_SECBOOT="QEMU_VARS.secboot.fd"

# Generate the PK and KEK keys
# Platform Key (PK) contains only one certificate which authorizes changes
# to the KEKs. The PK is usually set by the OEM
# Key Exchange Key (KEK) contains one or more certificates that authorize
# changes to the DB and DBX
for key in PK KEK; do
    openssl req -new -x509 -newkey rsa:2048 -nodes -days 3650 \
        -subj "/CN=Platform ${key}/" -keyout ${key}.key -out ${key}.crt -quiet
done

# Create the Root CA
# Root Certificate Authority (CA) represents the identity of the OEM
openssl req -new -x509 -newkey rsa:4048 -nodes -days 3650 \
    -subj "/CN=My Master Root CA/" -keyout rootCA.key -out rootCA.crt -quiet

# Export the Root CA to a PKCS#12 archive
openssl pkcs12 -export -out rootCA.p12 -inkey rootCA.key -in rootCA.crt \
    -name "MasterRootCA" -passout pass:${PASSWORD}

# Generate a DB Signing Key
# The DB maintains a list of certificates and hashes that identify
# trusted boot binaries
openssl genrsa -out db.key 2048

# Create a Certificate Signing Request (CSR) for the DB key
openssl req -new -key db.key -subj "/CN=DB Key Signer/" -out db.csr

# Sign the DB key with the Root CA and the CSR
openssl x509 -req -in db.csr -CA rootCA.crt -CAkey rootCA.key \
    -CAcreateserial -out db.crt -days 365 -passin pass:${PASSWORD} \

# Enroll the Root CA into the DB so it trusts anything the CA signs
virt-fw-vars --input ${QEMU_VARS} --output ${QEMU_VARS_SECBOOT} \
    --set-pk ${GUID} PK.crt \
    --add-kek ${GUID} KEK.crt \
    --add-db ${GUID} rootCA.crt \
    --sb

exit 0

KERNEL_UNSIGNED="vmlinuz"
KERNEL_SIGNED="vmlinuz.signed"

if [ -f ${KERNEL_UNSIGNED} ]
then
    # Sign the kernel binary, adding the Root CA to the signature
    sbsign --key db.key --cert db.crt --addcert rootCA.crt \
    --output ${KERNEL_SIGNED} ${KERNEL_UNSIGNED}
fi
