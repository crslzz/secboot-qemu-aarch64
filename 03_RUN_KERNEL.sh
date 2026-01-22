#!/bin/bash -xe

QEMU_CODE_SECBOOT=QEMU_CODE.secboot.fd
QEMU_VARS_SECBOOT=QEMU_VARS.secboot.fd

qemu-system-aarch64 \
	-nographic \
	-M virt -machine virtualization=true \
	-machine virt,gic-version=3 -cpu max,pauth-impdef=on \
	-m 2G \
	-drive if=pflash,format=raw,unit=0,file=${QEMU_CODE_SECBOOT},readonly=on \
	-drive if=pflash,format=raw,unit=1,file=${QEMU_VARS_SECBOOT} \
	-rtc base=localtime,clock=host \
	-kernel vmlinuz.signed \
	-append "console=ttyAMA0"
