{ lib, config, ... }:

let
  # TODO: Make this a module option, and as a list.
  # Re-use nix.buildMachines?
  #
  # { jenkins-nix-ci.remoteBuilders = [ "biryani "]; } -> automatically patches ssh.extraConfig
  #
  # Or, ditch this (slow?) and go with sshSlaves.
  remoteBuilder = {
    user = "admin";
    hostName = "biryani";
    hostIp = "100.97.32.60";  # Tailscale IP
    # system = "aarch64-darwin";
    # if the builder supports building for multiple architectures, 
    # replace the previous line by, e.g.,
    systems = [ "aarch64-darwin" "x86_64-darwin" ];
    # Retrieve this using `ssh-keyscan biryani`
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPu1awcmxDPpQ+srata5ORL+8j84GmVmf7mp/czLHn0r";
    maxJobs = 8;
    # The relative speed of this builder. This is an arbitrary integer that
    # indicates the speed of this builder, relative to other builders. Higher is
    # faster.
    speedFactor = 1;
  };
in {
  # Reuse jenkins master's ssh key for doing distrbuted builds from root@local.
  sops.secrets."jenkins-nix-ci/ssh-key/private".group = "root";

  programs.ssh.extraConfig = ''
    Host ${remoteBuilder.hostName}
      User ${remoteBuilder.user}
      HostName ${remoteBuilder.hostIp}
      IdentitiesOnly yes
      IdentityFile ${config.sops.secrets."jenkins-nix-ci/ssh-key/private".path}
  '';
  programs.ssh.knownHosts.biryani = {
    hostNames = [ remoteBuilder.hostName remoteBuilder.hostIp ];
    inherit (remoteBuilder) publicKey;
  };
  nix.distributedBuilds = true;
  nix.buildMachines = [{
    inherit (remoteBuilder)
      hostName systems maxJobs speedFactor;
    protocol = "ssh-ng";
    supportedFeatures = [ "benchmark" "big-parallel" "kvm" ];
    mandatoryFeatures = [ ];
  }];

  # When the builder has a faster internet connection than us.
  nix.extraOptions = ''
		builders-use-substitutes = true
  '';
}
