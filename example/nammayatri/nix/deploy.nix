{ self, inputs, ... }:

{
  flake.deploy.nodes.jenkins-nix-ci = {
    hostname = "100.96.121.13"; # Tailscale IP
    sshUser = "admin";
    profiles.system = {
      user = "root";
      path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.jenkins-nix-ci;
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
