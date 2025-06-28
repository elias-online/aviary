{...}: {
  config = {
    boot = {
      kernelParams = ["quiet" "splash"];

      plymouth = {
        enable = true;
        theme = "spinner";
      };

      #initrd.unl0kr.enable = true;
    };
  };
}
