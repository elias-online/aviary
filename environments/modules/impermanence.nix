{ config, lib, ... }: {

  options.impermanence.enable = lib.mkEnableOption "enable impermanence";

  config = lib.mkIf config.impermanence.enable {

    boot.initrd.systemd.services."impermanence" = {
      enable = true;
      description = "Backup then restore initial root BTRFS subvol, keeping ssh host key pair";
      after = [ "local-fs.target" "cryptsetup.target" ];
      before = [ "sysinit.target" ];
      wants = [ "local-fs.target" "cryptsetup.target" ];
      wantedBy = [ "sysinit.target" ];
      unitConfig = {
        DefaultDependencies = "no";
	AssertPathExists = "/etc/initrd-release";
      };

      script = ''
        echo "Impermanence script starting"
        mkdir /btrfs_tmp
        mount /dev/mapper/luksbtrfs /btrfs_tmp
        if [[ -e /btrfs_tmp/root ]]; then
            mkdir -p /btrfs_tmp/old_roots
            timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
            mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
        fi

        delete_subvolume_recursively() {
            IFS=$'\n'
            for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
                delete_subvolume_recursively "/btrfs_tmp/$i"
            done
            btrfs subvolume delete "$1"
        }
 
        btrfs subvolume create /btrfs_tmp/root
        mkdir -p /btrfs_tmp/root/etc/ssh
        cp "/btrfs_tmp/old_roots/$timestamp/etc/ssh/ssh_host_ed25519_key" \
            /btrfs_tmp/root/etc/ssh/ssh_host_ed25519_key
        cp "/btrfs_tmp/old_roots/$timestamp/etc/ssh/ssh_host_ed25519_key.pub" \
            /btrfs_tmp/root/etc/ssh/ssh_host_ed25519_key.pub

	for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +14); do
            delete_subvolume_recursively "$i"
        done

        umount /btrfs_tmp
        echo "Impermanence script ending"
        echo "changed 3-24"
      '';

      serviceConfig.Type = "oneshot";
    };

    fileSystems."/persist".neededForBoot = true;
    environment.persistence."/persist" = {
      hideMounts = true;
      directories = [
        "/etc/nixos"
        "/var/log"
        "/var/lib/nixos"
        "/var/lib/systemd/coredump"
        #{ directory = "/var/lib/colord"; user = "colord"; group = "colord"; mode = "u=rwx,g=rw,o="; }
      ];

      files = [
        "/etc/machine-id"
        "/var/keys/age_host_key"
        #{ file = "/var/keys/age_host_key"; parentDirectory = { mode = "u=rwx,g=,o="; }; }
      ];
    };
  };
}
