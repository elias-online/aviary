#!/bin/sh

echo "Ensure you are running this with sbsigntool and efitools packages present!"
echo "nix-shell -p sbsigntool efitools"
echo ""

sudo sbctl create-keys
sudo cert-to-efi-sig-list -g "$(uuidgen)" /var/lib/sbctl/keys/PK/PK.pem /var/lib/sbctl/keys/PK/PK.esl
sudo cert-to-efi-sig-list -g "$(uuidgen)" /var/lib/sbctl/keys/KEK/KEK.pem /var/lib/sbctl/keys/KEK/KEK.esl
sudo cert-to-efi-sig-list -g "$(uuidgen)" /var/lib/sbctl/keys/db/db.pem /var/lib/sbctl/keys/db/db.esl

sudo rm -rf /boot/EFI/HP
sudo mkdir -p /boot/EFI/HP
sudo sign-efi-sig-list -k /var/lib/sbctl/keys/PK/PK.key -c /var/lib/sbctl/keys/PK/PK.pem PK  /var/lib/sbctl/keys/PK/PK.esl /boot/EFI/HP/PK.bin
sudo sign-efi-sig-list -k /var/lib/sbctl/keys/PK/PK.key -c /var/lib/sbctl/keys/PK/PK.pem KEK  /var/lib/sbctl/keys/KEK/KEK.esl /boot/EFI/HP/KEK.bin
sudo sign-efi-sig-list -k /var/lib/sbctl/keys/KEK/KEK.key -c /var/lib/sbctl/keys/KEK/KEK.pem db  /var/lib/sbctl/keys/db/db.esl /boot/EFI/HP/DB.bin

echo "Created /boot/EFI/HP/PK.bin"
echo "Created /boot/EFI/HP/KEK.bin"
echo "Created /boot/EFI/HP/DB.bin"
echo ""
echo "Reboot to UEFI and import custom secureboot keys"
echo "Remember to remove the keys from the EFI partition afterwards:"
echo "sudo rm -rf /boot/EFI/HP"
