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
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = inputs.nixpkgs.lib.systems.flakeExposed;
      imports = [
        inputs.flake-root.flakeModule
        ./nix/ngrok-outputs.nix
        ./nix/jenkins/plugins/flake-module.nix
      ];
      flake = {
        # nixosModules.default = ./nix/jenkins.nix; # TODO: WIP (See #3)
        nixosConfigurations.jenkins-nix-ci = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            inputs.agenix.nixosModules.default
            ./nix/configuration.nix
            ./nix/ngrok.nix
            ./nix/jenkins.nix
            ({
              jenkins-nix-ci = {
                # Hardcoded domain spit out by ngrok
                domain = "b149-106-51-91-112.in.ngrok.io";
              };
            })
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
        packages = {
          docker-push = pkgs.writeShellApplication {
            name = "docker-push";
            runtimeInputs = [ pkgs.jq ];
            text = ''
              set -euo pipefail

              set -x
              docker load -i "$(nix build "$1" --print-out-paths)"
              set +x
              IMAGE_NAME="$(nix eval --json .#packages.x86_64-linux.dockerImage.buildArgs | jq '\"\(.name):\(.tag)\"')"
              echo "Built and loaded: ''${IMAGE_NAME}"

              echo "Logging in to Docker Registry"
              HOME="$(mktemp -d)"
              export HOME
              trap 'rm -rf "$HOME"'  EXIT
              echo "''${DOCKER_PASS}" | docker login -u "''${DOCKER_USER}" --password-stdin "''${DOCKER_SERVER}"
              set -x
              docker push "''${IMAGE_NAME}"
              set +x
              docker logout "''${DOCKER_SERVER}"
            '';
          };
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
    };
}
