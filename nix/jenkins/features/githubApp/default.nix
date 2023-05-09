{ cascLib, sops, lib, ... }:

let
  types = lib.types;
in
{
  options.features.githubApp = {
    enable = lib.mkEnableOption "githubApp";

    sopsSecrets = lib.mkOption {
      type = types.listOf types.str;
      readOnly = true;
      default = [
        "jenkins-nix-ci/github-app/appID"
        "jenkins-nix-ci/github-app/description"
        "jenkins-nix-ci/github-app/privateKey"
      ];
    };

    casc.credentials = lib.mkOption {
      type = types.listOf types.attrs;
      readOnly = true;
      default = [
        {
          # Instructions for creating this Github App are at:
          # https://github.com/jenkinsci/github-branch-source-plugin/blob/master/docs/github-app.adoc#configuration-as-code-plugin
          githubApp = {
            id = "github-app";
            appID = cascLib.readFile sops.secrets."jenkins-nix-ci/github-app/appID".path;
            description = cascLib.readFile sops.secrets."jenkins-nix-ci/github-app/description".path;
            privateKey = cascLib.readFile sops.secrets."jenkins-nix-ci/github-app/privateKey".path;
          };
        }
      ];
    };

    sharedLibrary = lib.mkOption {
      type = types.nullOr types.package;
      readOnly = true;
      default = null;
    };

    node.nixosConfiguration = lib.mkOption {
      type = types.deferredModule;
      readOnly = true;
      default = { };
    };

    node.darwinConfiguration = lib.mkOption {
      type = types.deferredModule;
      readOnly = true;
      default = { };
    };
  };
}
