{
  config,
  lib,
  pkgs,
  ...
}:

let

  inherit ( builtins )
    readFile
  ;
  
  inherit ( lib )
    mkIf
    mkOption
  ;

  inherit ( lib.types )
    bool
    str
  ;

  inherit ( pkgs )
    writeShellScript
  ;

  host = config.networking.hostName;

in {
  
  options.aviary = {

    ssh = mkOption {
      type = bool;
      default = true;
      example = false;
      description = "Enable SSH";
    };

    secrets = {

      sshHostInitrd = mkOption {
        type = str;
        default = host + "-ssh-host-initrd";
        example = "hostname-ssh-host-initrd";
        description = "SOPS-Nix secret storing the initrd hostkey";
      };
    };
  };

  config =

  let

    secrets = config.sops.secrets;
    secretsName = config.aviary.secrets;

    defaultPermissions = {
      mode = "0440";
      owner = config.users.users."1000".name;
      group = "admin";
    };

  in mkIf config.aviary.ssh {

    sops.secrets."${secretsName.sshHostInitrd}" = defaultPermissions; 

    boot.initrd = {
        
      availableKernelModules = [ "ccm" "ctr" ];

      network = {
        enable = true;
           
        ssh = {
          enable = true;
          extraConfig = "HostKey /etc/ssh/ssh_host_ed25519_key";
          authorizedKeys = config.users.users."1000".openssh.authorizedKeys.keys;
          
          # Prevent error since we're deploying keys out of band.
          ignoreEmptyHostKeys = true;
 
          # Using a different port prevents ssh clients from throwing MITM error.
          port = 2222;
        };
      };

      systemd =

      let

        wpaExecStart = writeShellScript "initrdwificonnect" ( readFile ../scripts/systemd/initrdwifi.sh );

      in {

        # Copy ssh host key into initrd. This has the unfortunate side effect of exposing
        # the key to all users on the system via nix store which is why we use a different
        # host key from the main system.
        tmpfiles.settings."10-ssh"."/etc/ssh/ssh_host_ed25519_key".f = {
          group = "root";
          mode = "0400";
          user = "root";
          argument = readFile secrets."${secretsName.sshHostInitrd}".path;
        };

        packages = [ pkgs.wpa_supplicant ];
        initrdBin = [ pkgs.wpa_supplicant ];

        users.root.shell = "/bin/systemd-tty-ask-password-agent"; 

        network.links."10-wifi" = {
          matchConfig.Type = "wlan";
          linkConfig.Name = "wifi0";
        };

        targets.cryptsetup.wants = [ "wpa_supplicant-initrd.service" ];

        services = {
          sshd.wantedBy = [ "systemd-ask-password-console.service" ]; 

          "wpa_supplicant@".enable = false;

          "wpa_supplicant-initrd" = {
            description = "WPA supplicant daemon (for interface wifi0)";
            before = [ "network.target" ];
            wants = [ "network.target" ];
            wantedBy = [ "multi-user.target" ];
            
            serviceConfig = { 
              ExecStart = "${wpaExecStart} disk-primary-luks-btrfs-${host}"; 
              TimeoutStartSec = 0;
              Type = "notify";
              NotifyAccess = "main";
            };

            unitConfig = {
              DefaultDependencies = false;
              IgnoreOnFailure = "yes";
            };
          };
        };

        storePaths = [ wpaExecStart ];
      };
    };

    services.openssh = {
      enable = true;
      ports = [ 22 ];
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        UseDns = true;
        PermitRootLogin = "prohibit-password";
      };

      hostKeys = [
        {
          path = "/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];
    };

    networking.firewall.allowedTCPPorts = [ 22 ];

    # Prevent GUI for inputting SSH credentials
    programs.ssh.askPassword = "";
  };
}
