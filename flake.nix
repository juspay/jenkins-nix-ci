{
  inputs = {
    jenkinsPlugins2nix.url = "github:Fuuzetsu/jenkinsPlugins2nix";
    flake-outputs.url = "github:nix-systems/flake-outputs";
    # To investigate a cachix push issue, we are using master
    # https://github.com/cachix/cachix/commit/24e0ba91600dc37ca050e44db03f7addb10a06be
    cachix.url = "github:cachix/cachix";
  };
  outputs = inputs: {
    nixosModules.default = { pkgs, ... }: {
      nixpkgs.overlays = [
        (self: super: {
          cachix = inputs.cachix.packages.${pkgs.system}.default;
          flake-outputs = inputs.flake-outputs.packages.${pkgs.system}.default;
          jenkinsPlugins2nix = inputs.jenkinsPlugins2nix.packages.${if pkgs.system == "aarch64-darwin" then "x86_64-darwin" else pkgs.system}.jenkinsPlugins2nix;
        })
      ];
      imports = [ ./nix/jenkins ];
    };
  };
}
