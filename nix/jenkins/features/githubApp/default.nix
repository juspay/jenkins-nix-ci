{ lib, config, secrets, ... }:

let
  types = lib.types;
  casc = config.cascLib;
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
            appID = casc.readFile secrets."jenkins-nix-ci/github-app/appID".path;
            description = casc.readFile secrets."jenkins-nix-ci/github-app/description".path;
            privateKey = casc.readFile secrets."jenkins-nix-ci/github-app/privateKey".path;
          };
        }
      ];
    };

    sharedLibrary = lib.mkOption {
      type = types.nullOr types.package;
      readOnly = true;
      default = null;
    };

    node.packages = lib.mkOption {
      type = types.listOf types.package;
      readOnly = true;
      default = [ ];
    };
  };
}
