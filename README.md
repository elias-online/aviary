# DEPLOYMENT
Where `<host>` corresponds to target you are deploying

### Build ISO on a Prexisting Nix Device
```
git clone https://github.com/elias-online/aviary && cd aviary
```
```
nix build .#nixosConfigurations.egg.config.system.build.isoImage
```

### Write ISO to a USB Drive
```
sudo dd if=result/iso/egg.iso of=/dev/<sdX> bs=4M status=progress oflag=sync
```

### UEFI Boot to USB Drive on `<host>` and Connect with SSH
```
ssh nixos@<address>
```

### Dump Info for Config
```
nixos-generate-config --no-filesystems --show-hardware-config
```
```
ls -l /dev/disk/by-id/
```

### Onboard `<host>`
```
echo <luks-password> | sudo tee /keyfile >/dev/null
```
```
sudo ssh-to-age -private-key -i /etc/ssh/ssh_host_ed25519_key | age-keygen -y
```
```
exit
```

### Update Your Secrets Repository
add `<host>` public age key to .sops.yaml
add `secrets/<user>.yaml` (optional)
```
sops updatekeys -y secrets/<user>.yaml
```
push changes to your secrets repository

### Update the Aviary Repository
```
nix flake update
```
add `system/<host>.nix`
add `users/<user>.nix` (optional)
add `<host>` to `flake.nix`


### Build the `<host>`
```
nixos-anywhere --copy-host-keys -f .#<host> nixos@<ip>
```

# MAINTENANCE

### CHECK BTRFS QUOTA LIMITS
```
sudo btrfs gqroup show -r /
```

### GARBAGE COLLECTION
```
nix-collect-garbage -d
```
