{ self, inputs, ... }:

let
  # TODO: Upstream this: https://github.com/serokell/deploy-rs/issues/210#issuecomment-1530857109
  deploy-activate-darwin = base: inputs.deploy-rs.lib."aarch64-darwin".activate.custom base.config.system.build.toplevel ''
    export HOME="/var/root"
    $PROFILE/activate
  '';
in
{
  flake.deploy.nodes = {
    # TODO: rename to Linux
    nixos = {
      hostname = "100.96.121.13"; # Tailscale IP
      sshUser = "admin";
      profiles.system = {
        user = "root";
        path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.jenkins-nix-ci;
      };
    };
    macos = {
      hostname = "100.97.32.60"; # Tailscale IP
      sshUser = "admin";
      profiles.system = {
        user = "root";
        path = deploy-activate-darwin self.darwinConfigurations.biryani;
      };
    };
  };

  perSystem = { self', inputs', system, lib, config, pkgs, ... }: {
    # checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) inputs.deploy-rs.lib;

    apps = {
      # Deploy
      default = {
        type = "app";
        program = "${inputs'.deploy-rs.packages.deploy-rs}/bin/deploy";
      };
    };
  };
}
