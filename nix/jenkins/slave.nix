# Base configuration for a Jenkins slave running in a container
{ pkgs, config, ... }: {
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };
  environment.etc."resolv.conf".text = "nameserver 8.8.8.8";

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  services.jenkinsSlave = {
    enable = true;
    inherit (config.services.jenkins) user;
  };

  environment.systemPackages = with pkgs; [
    git
    bash # 'sh' step requires this
    coreutils
    which
  ];
}
