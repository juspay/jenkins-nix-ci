{
  inputs = {
    jenkinsPlugins2nix.url = "github:Fuuzetsu/jenkinsPlugins2nix";
  };
  outputs = inputs: {
    nixosModules.default = import ./nix/jenkins { inherit (inputs) jenkinsPlugins2nix; };
  };
}
