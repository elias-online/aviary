{
  config,
  lib,
  pkgs,
  ...
}: {
  options.sshinitrd = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = false;
      description = "enable ssh in initrd";
    };

    hostKey = lib.mkOption {
      type = lib.types.str;
      default = config.networking.hostName + "-ssh-host-initrd";
      example = "hostname-ssh-host-initrd";
      description = "hostkey secret name in sops-nix";
    };
  };

  config = lib.mkIf config.sshinitrd.enable {

    sops.secrets."${config.sshinitrd.hostKey}" = {}; 

    boot = {
      initrd = {
        availableKernelModules = [ "ccm" "ctr" ];

        network = {
          enable = true;
           
          ssh = {
            enable = true;
            ignoreEmptyHostKeys = true; # prevent error since we're deploying keys out of band
            extraConfig = "HostKey /etc/ssh/ssh_host_ed25519_key";
            port = 2222; # using a different port prevents ssh clients from throwing MITM error
            authorizedKeys = config.users.users."1000".openssh.authorizedKeys.keys;
          };
        };

        systemd =

        let
          tmpfileContent = builtins.readFile config.sops.secrets."${config.sshinitrd.hostKey}".path;
          mapper =
            if builtins.pathExists /tmp/egg-drive-name
            then builtins.replaceStrings ["\n"] [""] (builtins.readFile /tmp/egg-drive-name)
            else config.networking.hostName;
          cryptsetupGeneratorService = "systemd-cryptsetup@disk\\x2dprimary\\x2dluks\\x2dbtrfs\\x2d" + mapper;
          wpaExecStart = (pkgs.writeShellScript "initrdwificonnect" ''${ builtins.readFile ../scripts/systemd/initrdwificonnect.sh }'');
          wpaExecStartPre = (pkgs.writeShellScript "initrdwifisetup" ''${ builtins.readFile ../scripts/systemd/initrdwifisetup.sh }'');
        in {

          packages = [ pkgs.wpa_supplicant ];
          initrdBin = [ pkgs.wpa_supplicant ];

          users.root.shell = "/bin/systemd-tty-ask-password-agent";

          # Copy ssh host key into initrd. This has the unfortunate side effect of exposing
          # the key to all users on the system via nix store which is why we use a different
          # host key from the main system.
          tmpfiles.settings."10-ssh"."/etc/ssh/ssh_host_ed25519_key".f = {
            group = "root";
            mode = "0400";
            user = "root";
            argument = tmpfileContent;
          };

          network.links."10-wifi" = {
            matchConfig.Type = "wlan";
            linkConfig.Name = "wifi0";
          };

          targets.cryptsetup.wants = [ "wpa_supplicant-initrd.service" ];

          services = {
            sshd.wantedBy = [ "systemd-ask-password-console.service" ];

            ${cryptsetupGeneratorService} = {
              after = [ "wpa_supplicant-initrd.service" ];
              requires = [ "wpa_supplicant-initrd.service" ];
            };

            "wpa_supplicant@".enable = false;

            "wpa_supplicant-initrd" = {
              description = "WPA supplicant daemon (for interface wifi0)";
              before = [ "network.target" ];
              wants = [ "network.target" ];
              wantedBy = [ "multi-user.target" ];
              serviceConfig = {
                ExecStartPre = "${wpaExecStartPre}";
                ExecStart = "${wpaExecStart}";
                TimeoutStartSec = 0;
                Type = "simple";
              };  

              unitConfig = {
                DefaultDependencies = false;
                IgnoreOnFailure = "yes";
              };
            };
          };

          storePaths = [
            wpaExecStart
            wpaExecStartPre
          ];
        };
      };
    };
  };
}
