{ pkgs, lib, config, ... }:

let
  cascLib = pkgs.callPackage ./casc/lib.nix { };
  localRetriever = pkgs.callPackage ./casc/local-retriever.nix { };
in
{
  config = {
    # Let jenkins user own the sops secrets associated with enabled features.
    sops.secrets =
      lib.foldl
        (acc: x: acc // { "${x}" = { owner = config.services.jenkins.user; }; })
        { }
        config.jenkins-nix-ci.feature-outputs.sopsSecrets;
  };
  options.jenkins-nix-ci.cascConfig = lib.mkOption {
    type = lib.types.attrs;
    readOnly = true;
    description = ''
      Config for configuration-as-code-plugin
                 
      This enable us to configure Jenkins declaratively rather than fiddle with
      the UI manually.
      cf:
      https://github.com/mjuh/nixos-jenkins/blob/master/nixos/modules/services/continuous-integration/jenkins/jenkins.nix
    '';
    default = {
      credentials.system.domainCredentials = [
        {
          inherit (config.jenkins-nix-ci.feature-outputs.casc) credentials;
        }
      ];
      jenkins = {
        # By default, a Jenkins install allows signups!
        securityRealm.local.allowsSignup = false;

        numExecutors = if config.jenkins-nix-ci.nodes.local.enable then 6 else 0;

        nodes =
          lib.flip lib.mapAttrsToList config.jenkins-nix-ci.nodes.containerSlaves.containers (name: container: {
            permanent = {
              inherit name;
              labelString = "nixos linux x86_64-linux";
              numExecutors = 1;
              remoteFS = config.services.jenkinsSlave.home;
              retentionStrategy = "always";
              launcher.ssh = {
                credentialsId = "ssh-private-key";
                host = container.localAddress;
                port = 22;
                sshHostKeyVerificationStrategy.manuallyTrustedKeyVerificationStrategy.requireInitialManualTrust = false;
              };
            };
          });
      };
      unclassified = {
        location.url = "https://${config.jenkins-nix-ci.domain}/";
        # https://github.com/jenkinsci/configuration-as-code-plugin/issues/725
        globalLibraries.libraries = [
          {
            name = "jenkins-nix-ci";
            defaultVersion = "main";
            implicit = true;
            retriever =
              localRetriever
                "jenkins-nix-ci-library"
                config.jenkins-nix-ci.feature-outputs.sharedLibrary;
          }
        ];
      };
    };
  };
}
