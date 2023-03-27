{ lib, pkgs, config, secrets, ... }:

let
  types = lib.types;
  casc = config.cascLib;
in
{
  options.features.cachix = {
    enable = lib.mkEnableOption "cachix";

    casc.credentials = lib.mkOption {
      type = types.listOf types.attrs;
      readOnly = true;
      default = [
        {
          string = {
            id = "cachix-auth-token";
            description = casc.readFile secrets."jenkins-nix-ci/cachix-auth-token/description".path;
            secret = casc.readFile secrets."jenkins-nix-ci/cachix-auth-token/secret".path;
          };
        }
      ];
    };

    sharedLibrary.vars = lib.mkOption {
      type = types.listOf types.path;
      default = [
        ../../../../groovy-library/cachixPush.groovy
      ];
    };

    node.packages = lib.mkOption {
      type = types.listOf types.package;
      readOnly = true;
      default = [
        pkgs.cachix
        (pkgs.callPackage ../../../../groovy-library/vars/cachixPush.nix { inherit pkgs; })
      ];
    };
  };
}
