{ config, cascLib, sops, lib, pkgs, ... }:

let
  types = lib.types;
in
{
  options.features.cachix = {
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
            description = cascLib.readFile sops.secrets."jenkins-nix-ci/cachix-auth-token/description".path;
            secret = cascLib.readFile sops.secrets."jenkins-nix-ci/cachix-auth-token/secret".path;
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

    node.nixosConfiguration = lib.mkOption {
      type = types.deferredModule;
      readOnly = true;
      default = { pkgs, ... }: {
        environment.systemPackages = [
          pkgs.cachix
        ];
      };
    };

    node.darwinConfiguration = lib.mkOption {
      type = types.deferredModule;
      readOnly = true;
      default = config.features.cachix.node.nixosConfiguration;
    };
  };
}
