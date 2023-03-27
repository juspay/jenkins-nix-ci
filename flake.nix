{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-root.url = "github:srid/flake-root";
    deploy-rs.url = "github:serokell/deploy-rs";
    agenix.url = "github:ryantm/agenix";
    jenkinsPlugins2nix.url = "github:Fuuzetsu/jenkinsPlugins2nix";
    nixos-flake.url = "github:srid/nixos-flake";
    sops-nix.url = "github:Mic92/sops-nix";
  };
  outputs = inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = inputs.nixpkgs.lib.systems.flakeExposed;
      imports = [
        inputs.nixos-flake.flakeModule
        inputs.flake-root.flakeModule
        ./nix/flake-module.nix
        ./nix/ngrok-outputs.nix
        ./nix/deploy.nix
      ];

      # TODO: Everything below (including some imports above) should be moved to
      # ./example

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

      # System configuration
      flake.nixosConfigurations.jenkins-nix-ci = self.nixos-flake.lib.mkLinuxSystem ({ pkgs, config, ... }: {
        imports = [
          inputs.agenix.nixosModules.default
          inputs.sops-nix.nixosModules.sops
          self.nixosModules.jenkins-master
          ./nix/configuration.nix
          ./nix/ngrok.nix
        ];
        sops.defaultSopsFile = ./secrets.yaml;
        sops.secrets."ngrok-tokens/shivaraj".owner = "root";

        sops.secrets."jenkins-nix-ci/cachix-auth-token/description".owner = "jenkins";
        sops.secrets."jenkins-nix-ci/cachix-auth-token/secret".owner = "jenkins";
        sops.secrets."jenkins-nix-ci/github-app/appID".owner = "jenkins";
        sops.secrets."jenkins-nix-ci/github-app/description".owner = "jenkins";
        sops.secrets."jenkins-nix-ci/github-app/privateKey".owner = "jenkins";
        sops.secrets."jenkins-nix-ci/docker-login/description".owner = "jenkins";
        sops.secrets."jenkins-nix-ci/docker-login/user".owner = "jenkins";
        sops.secrets."jenkins-nix-ci/docker-login/pass".owner = "jenkins";
      });

      perSystem = { self', inputs', system, lib, config, pkgs, ... }: {
        formatter = pkgs.nixpkgs-fmt;
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.nixpkgs-fmt
            inputs'.deploy-rs.packages.default
            inputs'.agenix.packages.agenix
            pkgs.sops
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
