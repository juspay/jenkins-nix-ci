{ pkgs, lib, config, flake, ... }:

let
  # Functions for working with configuration-as-code-plugin syntax.
  # https://github.com/jenkinsci/configuration-as-code-plugin/blob/master/docs/features/secrets.adoc#additional-variable-substitution
  casc = {
    # This is useful when reading secrets decrypted by agenix.
    # Never use builtins.readFile, https://github.com/ryantm/agenix#builtinsreadfile-anti-pattern
    readFile = path:
      "$" + "{readFile:" + path + "}";
    json = k: x:
      "$" + "{json:" + k + ":" + x + "}";
  };
in
{
  options.jenkins-nix-ci = lib.mkOption {
    type = lib.types.submodule {
      options = {
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
              credentials = [
                {
                  # Instructions for creating this Github App are at:
                  # https://github.com/jenkinsci/github-branch-source-plugin/blob/master/docs/github-app.adoc#configuration-as-code-plugin
                  githubApp = {
                    appID = "308117";
                    description = "Github App - jenkins-nammayatri";
                    id = "github-app";
                    privateKey = casc.readFile config.age.secrets.github-app-pem.path;
                  };
                }
                {
                  string = {
                    id = "cachix-auth-token";
                    description = "nammayatri.cachix.org auth token";
                    secret = casc.json "value" (casc.readFile config.age.secrets.cachix-token.path);
                  };
                }
                {
                  string = {
                    id = "docker-user";
                    description = "Docker user";
                    secret = casc.json "user" (casc.readFile config.age.secrets.docker-login.path);
                  };
                }
                {
                  string = {
                    id = "docker-pass";
                    description = "Docker password";
                    secret = casc.json "pass" (casc.readFile config.age.secrets.docker-login.path);
                  };
                }
              ];
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
          location.url = "https://${flake.config.jenkins-nix-ci.domain}/";
          # https://github.com/jenkinsci/configuration-as-code-plugin/issues/725
          globalLibraries.libraries = [
            # We load the library from the Nix store, as this would
            # make the setup self-contained. Jenkins doesn't support a
            # local path retriever, so we cheat by piggybacking on the
            # git backend.
            {
              name = "jenkins-nix-ci";
              defaultVersion = "main";
              implicit = true;
              retriever.legacySCM = {
                scm.git = {
                  userRemoteConfigs = [
                    {
                      url = builtins.toString (pkgs.callPackage ../../groovy-library/git.nix { });
                    }
                  ];
                };
              };
            }
          ];
        };
      };
    };
    default = { };
    description = "Options for the jenkins-nix-ci module.";
  };
}
