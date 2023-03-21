{ pkgs, lib, config, ... }:

let
  # Config for configuration-as-code-plugin
  #
  # This enable us to configure Jenkins declaratively rather than fiddle with
  # the UI manually.
  # cf:
  # https://github.com/mjuh/nixos-jenkins/blob/master/nixos/modules/services/continuous-integration/jenkins/jenkins.nix
  cascConfig = {
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
    unclassified.location.url = "https://${config.jenkins-nix-ci.domain}/";
  };

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
  options = {
    jenkins-nix-ci = lib.mkOption {
      type = lib.types.submodule {
        options = {
          port = lib.mkOption {
            type = lib.types.int;
            default = 9091;
            description = "The port to run Jenkins on.";
          };
          domain = lib.mkOption {
            type = lib.types.str;
            description = "The domain in which Jenkins is exposed to the outside world.";
          };
        };
      };
      default = { };
      description = "Options for the jenkins-nix-ci module.";
    };
  };
  config = {
    virtualisation.docker.enable = true;
    services.jenkins.extraGroups = [ "docker" ];

    age.secrets.docker-login = {
      owner = "jenkins";
      file = ../secrets/docker-login.age;
    };
    age.secrets.github-app-pem = {
      owner = "jenkins";
      file = ../secrets/github-app-pem.age;
    };
    age.secrets.cachix-token = {
      owner = "jenkins";
      file = ../secrets/cachix-token.age;
    };

    services.jenkins = {
      enable = true;
      inherit (config.jenkins-nix-ci) port;
      environment = {
        CASC_JENKINS_CONFIG =
          builtins.toString (pkgs.writeText "jenkins.json" (builtins.toJSON cascConfig));
      };
      packages = with pkgs; [
        # Add packages used by Jenkins plugins here.
        git
        bash # 'sh' step requires this
        coreutils
        which
        nix
        cachix
        docker
      ];
      plugins = import ./jenkins/plugins {
        inherit (pkgs) fetchurl stdenv;
      };
      extraJavaOptions = [
        # Useful when the 'sh' step b0rks.
        # https://stackoverflow.com/a/66098536/55246
        "-Dorg.jenkinsci.plugins.durabletask.BourneShellScript.LAUNCH_DIAGNOSTICS=true"
      ];
    };

    # To allow the local node to run as builder, supporting nix builds.
    # This should not be necessary with external build agents.
    nix.settings.allowed-users = [ "jenkins" ];
    nix.settings.trusted-users = [ "jenkins" ];
  };
}
