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

        # Building on local node is disabled.
        numExecutors = 0;

        nodes =
          let
            inherit (config.jenkins-nix-ci.nodes)
              sshSlaves;
            inherit (config.jenkins-nix-ci.nodes.containerSlaves)
              containers;
          in
          lib.flip lib.mapAttrsToList (sshSlaves // containers) (name: node: {
            permanent = {
              inherit name;
              inherit (node) labelString numExecutors;
              remoteFS = config.services.jenkinsSlave.home;
              retentionStrategy = "always";
              launcher.ssh = {
                credentialsId = "ssh-private-key";
                host = node.hostIP;
                port = 22;
                sshHostKeyVerificationStrategy.manuallyTrustedKeyVerificationStrategy.requireInitialManualTrust = false;
              };
            } // lib.optionalAttrs (name == "biryani") {
              nodeProperties = [{
                envVars.env = [
                  {
                    key = "PATH";
                    value = "/run/current-system/sw/bin/:/usr/bin:/bin:/usr/sbin:/sbin";
                  }
                  {
                    key = "JAVA_HOME";
                    # FIXME:
                    value = "/nix/store/sjcqcpqryfv9r9r5lxm47zw24pbjii79-zulu11.48.21-ca-jdk-11.0.11";
                  }
                ];
              }];
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
