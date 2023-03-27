{ pkgs, lib, config, flake, ... }:

let
  # Functions for working with configuration-as-code-plugin syntax.
  # https://github.com/jenkinsci/configuration-as-code-plugin/blob/master/docs/features/secrets.adoc#additional-variable-substitution
  casc = {
    # This is useful when reading secrets decrypted by agenix.
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
                    secret = casc.readFile config.sops.secrets.cachix_token.path;
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
            {
              name = "jenkins-nix-ci";
              defaultVersion = "main";
              implicit = true;
              retriever = localRetriever
                "jenkins-nix-ci-library"
                ../../groovy-library;
            }
          ];
        };
      };
    };
    default = { };
    description = "Options for the jenkins-nix-ci module.";
  };
}
