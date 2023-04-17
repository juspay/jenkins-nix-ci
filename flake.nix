{
  inputs = {
    jenkinsPlugins2nix.url = "github:Fuuzetsu/jenkinsPlugins2nix";
    flake-outputs.url = "github:nix-systems/flake-outputs";
    cachix.url = "github:cachix/cachix";
  };
  outputs = inputs: {
    nixosModules.default = {
      _module.args = {
        inherit (inputs) jenkinsPlugins2nix flake-outputs;
        cachix-master = inputs.cachix;
      };
      imports = [ ./nix/jenkins ];
    };
  };
}
