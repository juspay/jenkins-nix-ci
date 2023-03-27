{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    deploy-rs.url = "github:serokell/deploy-rs";
    jenkinsPlugins2nix.url = "github:Fuuzetsu/jenkinsPlugins2nix";
    nixos-flake.url = "github:srid/nixos-flake";
    sops-nix.url = "github:Mic92/sops-nix";
  };
  outputs = inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      flake.nixosModules.default = import ./nix/jenkins.nix { inherit (inputs) jenkinsPlugins2nix; };

      # TODO: Everything below (including some imports above) should be moved to
      # ./example

      systems = inputs.nixpkgs.lib.systems.flakeExposed;
      imports = [
        inputs.nixos-flake.flakeModule
        ./nix/ngrok-outputs.nix
        ./nix/deploy.nix
      ];
      # System configuration
      flake.nixosConfigurations.jenkins-nix-ci = self.nixos-flake.lib.mkLinuxSystem ({ pkgs, config, ... }: {
        imports = [
          inputs.sops-nix.nixosModules.sops

          # Jenkins module usage
          self.nixosModules.default
          ({
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
          })

          ./nix/configuration.nix
          ./nix/ngrok.nix
        ];
        sops.defaultSopsFile = ./secrets.yaml;
      });

      perSystem = { self', inputs', system, lib, config, pkgs, ... }: {
        formatter = pkgs.nixpkgs-fmt;
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.nixpkgs-fmt
            inputs'.deploy-rs.packages.default
            pkgs.sops
            (self.nixosConfigurations.jenkins-nix-ci.config.jenkins-nix-ci.nix-prefetch-jenkins-plugins pkgs)
          ];
        };

        # Library of apps to run in `Jenkinsfile`
        # TODO: Remove after this PR is merged: https://github.com/nammayatri/nammayatri/pull/284
        packages = {
          docker-push = pkgs.callPackage ./groovy-library/vars/dockerPush.nix { };
          cachix-push = pkgs.callPackage ./groovy-library/vars/cachixPush.nix { };
        };
      };
    };
}
