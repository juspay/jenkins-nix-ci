{ lib, pkgs, config, ... }:

let
  types = lib.types;
  casc = config.jenkins-nix-ci.cascLib;
  secrets = config.sops.secrets;
in
{
  options.jenkins-nix-ci.features.docker = {
    enable = lib.mkEnableOption "docker";

    sopsSecrets = lib.mkOption {
      type = types.listOf types.str;
      readOnly = true;
      default = [
        "jenkins-nix-ci/docker-login/description"
        "jenkins-nix-ci/docker-login/user"
        "jenkins-nix-ci/docker-login/pass"
      ];
    };

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
      readOnly = true;
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
        (pkgs.callPackage ./dockerPush.nix { })
      ];
    };
  };
}
