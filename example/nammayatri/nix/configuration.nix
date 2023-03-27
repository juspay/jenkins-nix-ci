# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # Bootloader.
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.kernelParams = [ "i915.force_probe=a780" ];

  # Setup keyfile
  boot.initrd.secrets = {
    "/crypto_keyfile.bin" = null;
  };

  networking.hostName = "jenkins-nix-ci"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  networking.interfaces.wlp5s0.useDHCP = true;
  # Set your time zone.
  time.timeZone = "Asia/Kolkata";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_IN";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_IN";
    LC_IDENTIFICATION = "en_IN";
    LC_MEASUREMENT = "en_IN";
    LC_MONETARY = "en_IN";
    LC_NAME = "en_IN";
    LC_NUMERIC = "en_IN";
    LC_PAPER = "en_IN";
    LC_TELEPHONE = "en_IN";
    LC_TIME = "en_IN";
  };


  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;

  # This is mainly to avoid prompts in deploy-rs
  security.sudo.wheelNeedsPassword = false;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.admin = {
    isNormalUser = true;
    description = "Admin User";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      neovim
      git
      tmux
    ];
    openssh.authorizedKeys.keys =
      let
        keys = {
          srid = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCYQ003p7fB5ICQehLwhDBomY9WzkNBeijkSw9ADGU+ECrPakeIH3pntUWRJH1W93vKnLqpkn6HLGEXD9MCR0s98uhh8hT7uAYCxQTbEeKT3PYkfz3oe7XaR8rE601sds0ZyFwH7l8cvK97pGr+uhFXAaohiV6VqmLVXhManEjZZ8GfYWBD9BCmIJk43G3OGa5QYFeHqztprXaJNU5dFPv2Uq2C+L6EvfCfkK2OO1BLZgL+Rai5jjyy6k0fcfsxxd9BdGUwqDhcBeyTIzX9rePMugf/xD+6uNRxTU+vjVpGUtFOw6rpgmVyFv9mn3QMNdQBc5hYKVbIQwMNGTzGgcQv";
          shivaraj = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCrKY9Z1oDz5zNOJxcOBnb9cIzlVdEMmhglT7RfCSrY041FqSxQwqJmeQJ1vSsK4MAQq03X4JTmeaxvtf3p/EwhEMh7a4PK4V+lzxydfsvqNuSiHC9Jg5HUQymgABYiOVv352EO6E9vmGdJIVrGB4TFxNbMh3kG9KCqszDlXMA9/fHCTJejvJOJ26f4qpXazQFqts/5wT2z2J75GvY5ngKeQzFd4x2rHmOWd1DH/nOq4drZNkzfOgvEBYSLha8WL4Sc8mNpAG5/7zDdqjA5i4b/M2zQzjE/kgglfk2y3CPAKMJC82gbv8mQy/Y9F4RNyn71Kx3iUWJVF22pOAb+aNYxFw9qRlCracVJxhXxRxRj9c092m6jbwUmC63RYCDrlen3dd9+AYxYBL1LjnzBT2xFdREHp6Wch2Y5JiXDtMV4x/hlH2saxkZNnfRcvNdG8GJrCmxOBgruBMspPCGEEzPZRlD/BAb25z2DVjMBIwZs7yIJTvocrTHzDa9dRmwJIqE= shivaraj@shivaraj.bh-MacBookPro";
          hemanth = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCqBXOWcjuosGOUm0AcnVrmDuFhRLoZwdDkISs5gt1gwMjd66wca4C8zySg3qSSXyz49/RNXfqnGCTajLuLQbWPkksH+hg8LWTGSMvLQ1p8wmg7bj8xQ0OIzAYDaPYLfz3G6tFOCvXAmOaPJOaK5lV63WaqBHc09aVx7Nff/pChE7TO1J00WnUACMUMNRXPFJntGxPlXXwlNEjE+tVzQ7faBgYVjoT631wAMZqOWiofKC6G+aYA+TqY6qlVSST39qFRKlou6sCx5Q5cqZ/MpNPvigZxzVKpQkve4Ir+WFzkJhmpsizQ9ty7hWzZ0TANXb0P1HTJRSWSemqGxw6jnwehCR9xtWNMgZkAuC7FSA/+Ou1HeHNEhX97lEHCdc8nMrKAWD4KXSoeLn3j8uuwm3U9r//p0JqVnjwgYQWhR37oYwRv1lEKoQOH0SI16+MrDqTNgqS/HPrsRBIJq5rqJjjy7JUkeBOWveHKqiTPxoL1sp7RITmaOD+4kx9PJr1eIzE= hemantmangla@hemantmangla-MacBookPro";
        };
      in
      [ keys.shivaraj keys.srid keys.hemanth ];
  };
  nix.settings.trusted-users = [ "@wheel" ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  hardware.enableRedistributableFirmware = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?

}
