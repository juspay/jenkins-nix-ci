{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-root.url = "github:srid/flake-root";
    deploy-rs.url = "github:serokell/deploy-rs";
    agenix.url = "github:ryantm/agenix";
    jenkinsPlugins2nix.url = "github:Fuuzetsu/jenkinsPlugins2nix";
  };
  outputs = inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } ({ config, ... }: {
      systems = inputs.nixpkgs.lib.systems.flakeExposed;
      imports = [
        inputs.flake-root.flakeModule
        ./nix/flake-module.nix
        ./nix/ngrok-outputs.nix
      ];
      # This produces self.nixosModules.jenkins-master module for NixOS.
      jenkins-nix-ci = {
        # Hardcoded domain spit out by ngrok
        domain = "b149-106-51-91-112.in.ngrok.io";
        plugins = [
          "github-api"
          "git"
          "github-branch-source"
          "workflow-aggregator"
          "ssh-slaves"
          "configuration-as-code"
        ];
        plugins-file = "nix/jenkins/plugins.nix";
      };
      flake = {
        nixosConfigurations.jenkins-nix-ci = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            inputs.agenix.nixosModules.default
            self.nixosModules.jenkins-master
            ./nix/configuration.nix
            ./nix/ngrok.nix
          ];
        };
        deploy.nodes.jenkins-nix-ci =
          let
            ngrokPort = 19112;
          in
          {
            hostname = "0.tcp.in.ngrok.io";
            sshOpts = [ "-p" (builtins.toString ngrokPort) ];
            sshUser = "admin";
            profiles.system = {
              user = "root";
              path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.jenkins-nix-ci;
            };
          };
      };
      perSystem = { self', inputs', system, lib, config, pkgs, ... }: {
        # checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) inputs.deploy-rs.lib;

        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.nixpkgs-fmt
            inputs'.deploy-rs.packages.default
            inputs'.agenix.packages.agenix
          ];
        };

        # Library of apps to run in `Jenkinsfile`
        # TODO: Remove after nammayatri change is merged
        packages = {
          docker-push = pkgs.callPackage ./groovy-library/vars/dockerPush.nix { };
          cachix-push = pkgs.callPackage ./groovy-library/vars/cachixPush.nix { };
        };

        apps = {
          # Deploy
          default = {
            type = "app";
            program = "${inputs'.deploy-rs.packages.deploy-rs}/bin/deploy";
          };
        };
        formatter = pkgs.nixpkgs-fmt;
      };
    });
}
