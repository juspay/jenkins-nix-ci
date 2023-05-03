{ flake, pkgs, ... }:
{
  imports = [
    flake.self.darwinModules.home-manager
  ];
  nix.settings = {
    extra-platforms = "aarch64-darwin x86_64-darwin";
    auto-optimise-store = true;
    trusted-users = [ "root" "admin" ];
  };

  services.nix-daemon.enable = true;

  home-manager.users.${flake.config.flake.deploy.nodes.macos.sshUser} = {
    home.stateVersion = "22.11";

    home.packages = with pkgs; [
      neovim
    ];

    programs.starship.enable = true;
    programs.zsh = {
      enable = true;
      envExtra = ''
        # Make Nix and home-manager installed things available in PATH.
        export PATH=/run/current-system/sw/bin/:/etc/profiles/per-user/$USER/bin:$PATH
      '';
    };
  };

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}