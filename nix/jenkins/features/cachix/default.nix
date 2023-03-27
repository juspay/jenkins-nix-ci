{ lib, pkgs, config, ... }:

let
  types = lib.types;
in
{
  options.features.cachix = {
    enable = lib.mkEnableOption "cachix";
    casc.credentials = [
      /* {
        string = {
          id = "cachix-auth-token";
          description = casc.readFile config.sops.secrets."jenkins-nix-ci/cachix-auth-token/description".path;
          secret = casc.readFile config.sops.secrets."jenkins-nix-ci/cachix-auth-token/secret".path;
        };
      } */
    ];

    sharedLibrary.vars = [
      ../../../../groovy-library/cachixPush.groovy
    ];

    node.packages = lib.mkOption {
      type = types.listOf types.package;
      default = [
        (pkgs.callPackage ../../../../groovy-library/vars/cachixPush.nix { inherit pkgs; })
      ];
    };
  };
}
