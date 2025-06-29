╭────────────────────────────────────────────────────────────────╮
│              /                                                 │
│ \\\' ,      / //' d8888          d8b                           │
│  \\\//    _/ /// d88888          Y8P                           │
│   \_-//' /  /\/ d88P888                                        │
│     \ ///  >   d88P 888 888  888 888  8888b.  888d888 888  888 │
│    /,)-^>>  _ d88P  888 888  888 888     "88b 888P"   888  888 │
│    (/   \\ / d88P   888 Y88  88P 888 .d888888 888     888  888 │
│          // d8888888888  Y8bd8P  888 888  888 888     Y88b 888 │
│         ((`d88P     888   Y88P   888 "Y888888 888      "Y88888 │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 888 │
│   A CI/CD driven, secrets enabled, semiephemeral Nix  Y8b d88P │
│ network enabling simple system management & opperation "Y88P"  │
╰────────────────────────────────────────────────────────────────╯

# ABOUT
Aviary is an opinionated NixOS flake configuration designed to facility easy system management and use. To reach this end, it takes a hard stance on the following:

 1. Test first, implement second, CI/CD always
 2. Deployment is one step
 3. PII (Personally Identifiable Information) is a secret 
 4. Impermanence at the root level
 5. Modularity for flexibility

# FEATURES
 - Iso-free deployment
 - LUKS encrypted BTRFS partitioning
 - Systemd from bootloader to system
 - Tailscale for everything
 - SOPS encrypted secrets
 - Headless decryption
 - Optional Gnome Desktop

# TODO
 - Initrd interactive wifi connection for Recovery
 - Initrd VPN connection no experation option
 - SHA512 hashed password to prevent storing SOPS password secret in plain-text
 - Log out of tailscale before shutdown if ephemeral ts key
 - Test hardware.enableAllFirmware = true in environment/modules/default.nix
 - Test Hyprland

# SETUP

### Set up your private SOPS secrets repo

### Clone Aviary
```
git clone https://github.com/elias-online/aviary && cd aviary
```

### Change aviarySecrets flake input

# DEPLOYMENT

### Run secrets/deploy.sh

# MAINTENANCE

### Check BTRFS quota limits
```
sudo btrfs qgroup show -r /
```

### Garbage Collection
```
nix-collect-garbage -d
```

# SECUREBOOT NOTES

### HP Key Import Process

```
nix-shell -p sbsigntool efitools
sudo sbctl create-keys
sudo cert-to-efi-sig-list -g "$(uuidgen)" /var/lib/sbctl/keys/PK/PK.pem /var/lib/sbctl/keys/PK/PK.esl
sudo cert-to-efi-sig-list -g "$(uuidgen)" /var/lib/sbctl/keys/KEK/KEK.pem /var/lib/sbctl/keys/KEK/KEK.esl
sudo cert-to-efi-sig-list -g "$(uuidgen)" /var/lib/sbctl/keys/db/db.pem /var/lib/sbctl/keys/db/db.esl

sudo rm -rf /boot/EFI/HP
sudo mkdir -p /boot/EFI/HP
sudo sign-efi-sig-list -k /var/lib/sbctl/keys/PK/PK.key -c /var/lib/sbctl/keys/PK/PK.pem PK  /var/lib/sbctl/keys/PK/PK.esl /boot/EFI/HP/PK.bin
sudo sign-efi-sig-list -k /var/lib/sbctl/keys/PK/PK.key -c /var/lib/sbctl/keys/PK/PK.pem KEK  /var/lib/sbctl/keys/KEK/KEK.esl /boot/EFI/HP/KEK.bin
sudo sign-efi-sig-list -k /var/lib/sbctl/keys/KEK/KEK.key -c /var/lib/sbctl/keys/KEK/KEK.pem db  /var/lib/sbctl/keys/db/db.esl /boot/EFI/HP/DB.bin
```

Import custom secureboot keys via UEFI
