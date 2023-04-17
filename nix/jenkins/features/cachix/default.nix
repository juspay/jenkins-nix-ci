{ cachix-master, lib, pkgs, config, ... }:

let
  types = lib.types;
  casc = config.jenkins-nix-ci.cascLib;
  secrets = config.sops.secrets;
in
{
  options.jenkins-nix-ci.features.cachix = {
    enable = lib.mkEnableOption "cachix";

    sopsSecrets = lib.mkOption {
      type = types.listOf types.str;
      readOnly = true;
      default = [
        "jenkins-nix-ci/cachix-auth-token/description"
        "jenkins-nix-ci/cachix-auth-token/secret"
      ];
    };

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

    sharedLibrary = lib.mkOption {
      type = types.package;
      readOnly = true;
      default = pkgs.runCommand "cachix-groovy" { } ''
        mkdir -p $out/vars
        cp ${./cachixUse.groovy} $out/vars/cachixUse.groovy
        cp ${./cachixPush.groovy} $out/vars/cachixPush.groovy
      '';
    };

    node.packages = lib.mkOption {
      type = types.listOf types.package;
      readOnly = true;
      default = [
        pkgs.cachix
        (pkgs.callPackage ./cachixPush.nix { inherit cachix-master; })
      ];
    };
  };
}
