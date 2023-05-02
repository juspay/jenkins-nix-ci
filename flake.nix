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
    nixosModules.default = { pkgs, ... }: {
      nixpkgs.overlays = [
        (self: super: {
          cachix = inputs.cachix.packages.${pkgs.system}.default;
          flake-outputs = inputs.flake-outputs.packages.${pkgs.system}.default;
          devour-flake = self.callPackage inputs.devour-flake { };
          jenkinsPlugins2nix = inputs.jenkinsPlugins2nix.packages.${pkgs.system}.jenkinsPlugins2nix;
        })
      ];
      imports = [ ./nix/jenkins ];
    };
  };
}
