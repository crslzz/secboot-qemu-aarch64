#!/bin/bash -xe

IMAGE=secureboot-signed.img

QEMU_CODE_SECBOOT=./QEMU_CODE.secboot.fd
QEMU_VARS_SECBOOT=./QEMU_VARS.secboot.fd

qemu-system-aarch64 \
    -nographic \
    -M virt -machine virtualization=true \
    -machine virt,gic-version=3 -cpu max,pauth-impdef=on \
    -smp 2 -m 2G \
    -drive file=${QEMU_CODE_SECBOOT},if=pflash,format=raw,unit=0,readonly=on \
    -drive file=${QEMU_VARS_SECBOOT},if=pflash,format=raw,unit=1,snapshot=on,readonly=off \
    -drive file=${IMAGE},index=0,media=disk,format=raw,if=virtio,id=rootdisk,snapshot=off

