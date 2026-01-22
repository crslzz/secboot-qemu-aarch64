# secboot-qemu-aarch64
AutoSD 10 with Secure Boot for QEMU on aarch64


01_GENKEY_ENROLL.sh
  Generate the platform keys and Root CA
  Export them to a PKCS#12 archive
  Enrolls them into the AAVMF vars file

02_PESIGN_KERNEL.sh (optional)
  Sign a test kernel using the PKCS#12 archive

03_RUN_KERNEL.sh (optional)
  Run the signed kernel to verify that Secure Boot is enabled

04_BUILD_SECBOOT.sh
  Build an unsigned AutoSD 10 image
  Prepare the image for reseal
  Extract the EFI files to sign
  Sign the EFI files
  Inject the signed EFI files and reseal the image
  Generate a signed disk image

05_RUN_SECBOOT.sh
  Run the signed disk image to verify that Secure Boot is enabled

sign-file.sh
  Sign the EFI files (note the new --nssdb option)

AAVMF_CODE.secboot.fd.debian
AAVMF_VARS.fd.debian
  Debian's prebuilt AAVMF binaries from
  http://ftp.debian.org/debian/pool/main/e/edk2/qemu-efi-aarch64_2025.11-3_all.deb
