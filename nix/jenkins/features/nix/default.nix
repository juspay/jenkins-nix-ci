args@{ lib, pkgs, config, flake-outputs, ... }:

let
  types = lib.types;
  casc = config.jenkins-nix-ci.cascLib;
  secrets = config.sops.secrets;
in
{
  options.jenkins-nix-ci.features.nix = {
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
      '';
    };

    node.packages = lib.mkOption {
      type = types.listOf types.package;
      readOnly = true;
      default = 
        let 
          flake-outputs = args.flake-outputs.packages.${pkgs.system}.default;
        in [ 
          flake-outputs
          (pkgs.callPackage ./nixBuildAll.nix { inherit flake-outputs; })
        ];
    };
  };
}
