{ self, inputs, ... }:

{
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
          # This file can be updated by running:
          #   nix-prefetch-jenkins-plugins > nix/jenkins/plugins.nix
          plugins-file = "example/nammayatri/nix/jenkins-plugins.nix";
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
  };
}
