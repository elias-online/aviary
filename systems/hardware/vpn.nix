{ pkgs, tskey ? throw "Set the tskey", ... }: {

  services.tailscale.enable = true;

  systemd.services.tailscale-autoconnect = {
    description = "Automatic connection to Tailscale";
    after = [ "network-pre.target" "tailscale.service" ];
    wants = [ "network-pre.target" "tailscale.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = with pkgs; ''
      sleep 2

      status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
      if [ $status = "Running" ]; then
        exit 0
      fi

      authKey="$(cat ${builtins.toString tskey})"
      ${tailscale}/bin/tailscale up -authkey "$authKey"
    '';
  };

  environment.persistence."/persist".directories = [
    "/var/lib/tailscale"
  ];
}
