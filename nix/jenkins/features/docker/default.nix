{ cascLib, sops, lib, pkgs, ... }:

let
  types = lib.types;
in
{
  options.features.docker = {
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
            description = cascLib.readFile sops.secrets."jenkins-nix-ci/docker-login/description".path + " User";
            secret = cascLib.readFile sops.secrets."jenkins-nix-ci/docker-login/user".path;
          };
        }
        {
          string = {
            id = "docker-pass";
            description = cascLib.readFile sops.secrets."jenkins-nix-ci/docker-login/description".path + " Password";
            secret = cascLib.readFile sops.secrets."jenkins-nix-ci/docker-login/pass".path;
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

    node.config = lib.mkOption {
      type = types.deferredModule;
      readOnly = true;
      default = { pkgs, ... }: {
        environment.systemPackages = [
          pkgs.docker
          (pkgs.callPackage ./dockerPush.nix { })
        ];

        virtualisation.docker.enable = true;
        users.users.jenkins.extraGroups = [ "docker" ];
      };
    };
  };
}
