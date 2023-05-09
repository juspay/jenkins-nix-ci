# Converts a nix/jenkins/nodes.nix:nodeSubMmodule config to a Jenkins node CASC
# config.
{ config, ... }:
let
  mkNode = name: node: {
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
      nodeProperties = [{
        envVars.env = [
          # The Jenkins pipeline steps will see these environment variables.
          # PATH is essential to make nix and friends available to jobs.
          {
            key = "PATH";
            value = "/run/current-system/sw/bin/:/usr/bin:/bin:/usr/sbin:/sbin";
          }
        ];
      }];
    };
  };
in
mkNode
