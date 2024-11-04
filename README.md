# DEPLOYMENT
Where `<host>` corresponds to target to build

### BUILD ISO
```
user@local:~$ nix build .#nixosConfigurations.egg.config.system.build.isoImage
```

### DUMP CONFIG INFO
```
nixos@egg:~$ nixos-generate-config --no-filesystems --show-hardware-config
nixos@egg:~$ ls -l /dev/disk/by-id/
```

### CREATE HOST FILE
add `hosts/<host>.nix` to this repo  
add `<host>` to `flake.nix`

### ONBOARDING
```
nixos@egg:~$ echo <luks-password> | sudo tee /keyfile >/dev/null
nixos@egg:~$ sudo ssh-to-age -private-key -i /etc/ssh/ssh_host_ed25519_key | age-keygen -y
```
Add the generated age key to your sops secrets repo
```
user@local:~$ nixos-anywhere --copy-host-keys -f .#<host> nixos@<ip>
```

# MAINTENANCE

### CHECK BTRFS QUOTA LIMITS
```
$ sudo btrfs gqroup show -r /
```

### GARBAGE COLLECTION
```
$ nix-collect-garbage -d
```
