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
 - Clean up services/vpn.nix
 - Clean up initrd services
 - Remove need for --impure when building/rebuilding all systems except egg
 - Use ephemeral Tailscale keys for all connections
 - Get auto updates to work for systems that didn't update flake.lock themselves
 - Beautify Aviary boot sequence messages

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

### Enroll TPM2
```
systemd-cryptenroll /dev/disk/by-partlable/disk-primary-luks-hostname --tpm2-device=auto --tpm2-pcrs=0+2+4+7
```

# FEATURE MATRIX

```
+================================================================+
|             | ARM64 | AMD64 | SB | TPM2 | 2SSD | Nvidia | Wifi |
+================================================================+
| Cardinal    |       |  ✅   | ✅ |  ✅  |  ✅  |   ✅   |  ✅  |
|----------------------------------------------------------------|
| Crow        |       |  ✅   | ✅ |  ✅  |  ❌  |   ✅   |  ✅  |
|----------------------------------------------------------------|
| Egg         |       |  ✅   | ❌ |  ❌  |  ❌  |   ❌   |  ✅  |
|-------------|--------------------------------------------------|
| Hummingbird |       |  ✅   | ✅ |  ✅  |  ❌  |   ❌   |  ✅  |
|-------------|--------------------------------------------------|
| Ibis        |       |  ✅   | ✅ |  ✅  |  ❌  |   ❌   |  ✅  |
|-------------|--------------------------------------------------|
| Pigeon      |       |  ✅   | ✅ |  ✅  |  ✅  |   ❌   |  ❌  |
|-------------|--------------------------------------------------|
| Quail       |       |  ✅   | ❌ |  ❌  |  ❌  |   ❌   |  ✅  |
|-------------|--------------------------------------------------|
| Seagull     |       |  ✅   | ❌ |  ❌  |  ❌  |   ❌   |  ❌  |
|-------------|--------------------------------------------------|
| Swallow     |       |       |    |      |      |        |      |
+================================================================+
```
