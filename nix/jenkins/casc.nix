{ pkgs, lib, config, ... }:

let
  enabledFeatures = lib.filterAttrs (n: v: v.enable) config.jenkins-nix-ci.features;
  features_credentials =
    lib.concatMap (cfg: cfg.casc.credentials) (lib.attrValues enabledFeatures);
  features_sharedLibrary =
    let
      sharedLibraries = lib.concatMap
        (cfg: if cfg.sharedLibrary == null then [ ] else [ cfg.sharedLibrary ])
        (lib.attrValues enabledFeatures);
    in
    pkgs.buildEnv {
      name = "jenkins-nix-ci-library-enabled-features";
      # Just merge the individual libraries, because we expect them to have
      # `./vars` only.
      paths = sharedLibraries;
    };

  # Functions for working with configuration-as-code-plugin syntax.
  # https://github.com/jenkinsci/configuration-as-code-plugin/blob/master/docs/features/secrets.adoc#additional-variable-substitution
  casc = {
    # This is useful when reading secrets decrypted by sops-nix.
    # Never use builtins.readFile, https://github.com/ryantm/agenix#builtinsreadfile-anti-pattern
    readFile = path:
      "$" + "{readFile:" + path + "}";
    # Parse the string secret as JSON, then extract the value for the specified <key>.
    # https://github.com/jenkinsci/configuration-as-code-plugin/blob/master/docs/features/secrets.adoc#json
    json = key: x:
      "$" + "{json:" + key + ":" + x + "}";
  };

  # Jenkins doesn't support a local retriever; so we simulate one by
  # piggybacking on its git scm retriever.
  #
  # `localPath` is local path, typically a nix store path. Internally, a new
  # store path is created as a copy of it but with a git index, so Jenkins' git
  # scm retriever can access it.
  localRetriever = name: localPath:
    let
      pathInGit = path: pkgs.runCommand name
        {
          buildInputs = [ pkgs.git ];
        }
        ''
          mkdir -p $out
          cp -r ${path}/* $out
          cd $out
          git init
          git add .
          git config user.email "nobody@localhost"
          git config user.name "nix"
          git commit -m "Added by pkgs.runCommand (for localRetriever)"
        '';
    in
    {
      legacySCM.scm.git.userRemoteConfigs = [{
        url = builtins.toString (pathInGit localPath);
      }];
    };
in
{
  config = {
    sops.secrets."jenkins-nix-ci/cachix-auth-token/description".owner = "jenkins";
    sops.secrets."jenkins-nix-ci/cachix-auth-token/secret".owner = "jenkins";
    sops.secrets."jenkins-nix-ci/github-app/appID".owner = "jenkins";
    sops.secrets."jenkins-nix-ci/github-app/description".owner = "jenkins";
    sops.secrets."jenkins-nix-ci/github-app/privateKey".owner = "jenkins";
    sops.secrets."jenkins-nix-ci/docker-login/description".owner = "jenkins";
    sops.secrets."jenkins-nix-ci/docker-login/user".owner = "jenkins";
    sops.secrets."jenkins-nix-ci/docker-login/pass".owner = "jenkins";
  };
  options.jenkins-nix-ci = lib.mkOption {
    type = lib.types.submodule {
      options = {
        cascLib = lib.mkOption {
          type = lib.types.attrsOf lib.types.raw;
          description = "Casc library of functions";
          default = casc;
        };
        cascConfig = lib.mkOption {
          type = lib.types.attrs;
          description = ''
            Config for configuration-as-code-plugin
                 
            This enable us to configure Jenkins declaratively rather than fiddle with
            the UI manually.
            cf:
            https://github.com/mjuh/nixos-jenkins/blob/master/nixos/modules/services/continuous-integration/jenkins/jenkins.nix
          '';
        };
      };
      # TODO: Build cascConfig based on the parametrized options in flake-parts module
      config.cascConfig = {
        credentials = {
          system.domainCredentials = [
            {
              credentials = features_credentials;
            }
          ];
        };
        jenkins = {
          numExecutors = 6;
          securityRealm = {
            local = {
              allowsSignup = false;
            };
          };
        };
        unclassified = {
          location.url = "https://${config.jenkins-nix-ci.domain}/";
          # https://github.com/jenkinsci/configuration-as-code-plugin/issues/725
          globalLibraries.libraries = [
            {
              name = "jenkins-nix-ci";
              defaultVersion = "main";
              implicit = true;
              retriever = localRetriever
                "jenkins-nix-ci-library"
                features_sharedLibrary;
            }
          ];
        };
      };
    };
    default = { };
    description = "Options for the jenkins-nix-ci module.";
  };
}
