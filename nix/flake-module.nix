{ self, config, lib, flake-parts-lib, withSystem, ... }:

let
  inherit (flake-parts-lib)
    mkPerSystemOption;
  inherit (lib)
    mkOption
    types;
  inherit (types)
    functionTo
    raw;
in
{
  options =
    let
      topModule = types.submodule {
        options = {
          port = lib.mkOption {
            type = lib.types.int;
            default = 9091;
            description = "The port to run Jenkins on.";
          };
          domain = lib.mkOption {
            type = lib.types.str;
            description = "The domain in which Jenkins is exposed to the outside world.";
          };
        };
      };
    in
    {
      jenkins-nix-ci = mkOption {
        type = topModule;
        default = { };
        description = ''
          Jenkins Nix CI configuration.
        '';
      };
    };

  config = {
    flake.nixosModules.jenkins-master = { pkgs, ... }: {
      imports = [ ./jenkins.nix ];
      jenkins-nix-ci = {
        inherit (config.jenkins-nix-ci) port domain;
      };
    };
  };
}
