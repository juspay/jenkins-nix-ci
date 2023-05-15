{
  inputs = {
    jenkinsPlugins2nix.url = "github:Fuuzetsu/jenkinsPlugins2nix";
    flake-outputs.url = "github:nix-systems/flake-outputs";
    # Downgrade cachix to obviate https://github.com/cachix/cachix/issues/529
    cachix.url = "github:cachix/cachix/v1.3.3";
    devour-flake.url = "github:srid/devour-flake";
    devour-flake.flake = false;
  };
  outputs = inputs: {
    overlay = flake: self: super: {
      cachix = inputs.cachix.packages.${self.system}.default;
      flake-outputs = inputs.flake-outputs.packages.${self.system}.default;
      devour-flake = self.callPackage inputs.devour-flake { };
      jenkinsPlugins2nix = inputs.jenkinsPlugins2nix.packages.${if self.system == "aarch64-darwin" then "x86_64-darwin" else self.system}.jenkinsPlugins2nix;
    };

    nixosModules = rec {
      # The common module will work on NixOS and macOS alike.
      common = { flake, pkgs, ... }: {
        nixpkgs.overlays = [ (inputs.self.overlay flake) ];
      };

      # The default NixOS module.
      default = {
        imports = [
          common
          ./nix/jenkins
        ];
      };
    };

    # Modules to use in nix-darwin
    darwinModules = {
      default = inputs.self.nixosModules.common;
      slave = ./nix/jenkins/slave/macos.nix;
    };
  };
}
