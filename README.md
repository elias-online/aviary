# DEPLOYMENT

### BUILD ISO
```
user@local:~$ nix build .#nixosConfigurations.egg.config.system.build.isoImage
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
