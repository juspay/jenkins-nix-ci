{ self, config, ... }:

{
  flake = {
    # Configurations for macOS machines
    darwinConfigurations.biryani = self.nixos-flake.lib.mkARMMacosSystem ({ flake, pkgs, ... }: {
      imports = [
        flake.inputs.jenkins-nix-ci.darwinModules.default
        ./jenkins-ssh-slave.nix
        ../tailscale.nix

        # Your nix-darwin configuration goes here
        {
          nix.settings = {
            experimental-features = "nix-command flakes";
            extra-platforms = "aarch64-darwin x86_64-darwin";
            auto-optimise-store = true;
            trusted-users = [ "root" "admin" ];
          };

          services = {
            nix-daemon.enable = true;
          };

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 4;
        }
        # Setup home-manager in nix-darwin config
        self.darwinModules.home-manager
        {
          home-manager.users.${config.flake.deploy.nodes.macos.sshUser} = {
            imports = [ self.homeModules.default ];
            home.stateVersion = "22.11";
          };
        }
      ];
    });

    # home-manager configuration goes here.
    homeModules.default = { pkgs, ... }: {
      imports = [ ];
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
  };
}
