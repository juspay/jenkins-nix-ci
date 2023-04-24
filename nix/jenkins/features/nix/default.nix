{ lib, pkgs, ... }:

let
  types = lib.types;
in
{
  options.features.nix = {
    enable = lib.mkEnableOption "nix";

    sopsSecrets = lib.mkOption {
      type = types.listOf types.str;
      readOnly = true;
      default = [ ];
    };

    casc.credentials = lib.mkOption {
      type = types.listOf types.attrs;
      readOnly = true;
      default = [ ];
    };

    sharedLibrary = lib.mkOption {
      type = types.package;
      readOnly = true;
      default = pkgs.runCommand "nix-groovy" { } ''
        mkdir -p $out/vars
        cp ${./nixBuildAll.groovy} $out/vars/nixBuildAll.groovy
        cp ${./nixBuild.groovy} $out/vars/nixBuild.groovy
      '';
    };

    node.config = lib.mkOption {
      type = types.deferredModule;
      readOnly = true;
      default = { pkgs, jenkins, ... }: {
        environment.systemPackages = with pkgs; [
          nix
          flake-outputs
          devour-flake-cat
        ];

        nix.settings = {
          allowed-users = [ jenkins.user ];
          trusted-users = [ jenkins.user ];
          experimental-features = [ "nix-command" "flakes" ];
        };
      };
    };
  };
}
