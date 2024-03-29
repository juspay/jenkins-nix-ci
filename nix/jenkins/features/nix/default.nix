{ config, lib, pkgs, ... }:

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
        cp ${./nixCI.groovy} $out/vars/nixCI.groovy
        cp ${./nixBuild.groovy} $out/vars/nixBuild.groovy
      '';
    };

    node.nixosConfiguration = lib.mkOption {
      type = types.deferredModule;
      readOnly = true;
      default = { pkgs, jenkins, ... }: {
        environment.systemPackages = with pkgs; [
          nix
          flake-outputs
          devour-flake
          nixci
          (pkgs.callPackage ./nixBuildAll.nix { })
        ];

        nix.settings = {
          allowed-users = [ jenkins.user ];
          trusted-users = [ jenkins.user ];
          experimental-features = [ "nix-command" "flakes" ];
        };
      };
    };

    node.darwinConfiguration = lib.mkOption {
      type = types.deferredModule;
      readOnly = true;
      default = config.features.nix.node.nixosConfiguration;
    };
  };

}
