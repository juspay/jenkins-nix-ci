{
  inputs = {
    jenkinsPlugins2nix.url = "github:Fuuzetsu/jenkinsPlugins2nix";
  };
  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      flake.nixosModules.default = import ./nix/jenkins { inherit (inputs) jenkinsPlugins2nix; };
    };
}
