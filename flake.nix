{
  inputs = {
    jenkinsPlugins2nix.url = "github:Fuuzetsu/jenkinsPlugins2nix";
    flake-outputs.url = "github:srid/flake-outputs";
  };
  outputs = inputs: {
    nixosModules.default = {
      _module.args = {
        inherit (inputs) jenkinsPlugins2nix flake-outputs;
      };
      imports = [ ./nix/jenkins ];
    };
  };
}
