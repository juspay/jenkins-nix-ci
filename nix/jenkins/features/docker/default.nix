{ lib, pkgs, config, secrets, ... }:

let
  types = lib.types;
  casc = config.cascLib;
in
{
  options.features.docker = {
    enable = lib.mkEnableOption "docker";

    casc.credentials = lib.mkOption {
      type = types.listOf types.attrs;
      readOnly = true;
      default = [
        {
          string = {
            id = "docker-user";
            description = casc.readFile secrets."jenkins-nix-ci/docker-login/description".path + " User";
            secret = casc.readFile secrets."jenkins-nix-ci/docker-login/user".path;
          };
        }
        {
          string = {
            id = "docker-pass";
            description = casc.readFile secrets."jenkins-nix-ci/docker-login/description".path + " Password";
            secret = casc.readFile secrets."jenkins-nix-ci/docker-login/pass".path;
          };
        }
      ];
    };

    sharedLibrary = lib.mkOption {
      type = types.package;
      default = pkgs.runCommand "docker-groovy" { } ''
        mkdir -p $out/vars
        cp ${./dockerPush.groovy} $out/vars/dockerPush.groovy
      '';
    };

    node.packages = lib.mkOption {
      type = types.listOf types.package;
      readOnly = true;
      default = [
        pkgs.docker
        (pkgs.callPackage ../../../../groovy-library/vars/dockerPush.nix { inherit pkgs; })
      ];
    };
  };
}
