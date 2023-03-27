{ lib, config, ... }:

{

  # TODO: The following configuration will be moved to slaves when we set them up.

  # To allow the local node to run as builder, supporting nix builds.
  # This should not be necessary with external build agents.
  nix.settings.allowed-users = [ "jenkins" ];
  nix.settings.trusted-users = [ "jenkins" ];

  # Install docker so we can build images.
  virtualisation.docker.enable = lib.mkIf config.jenkins-nix-ci.features.docker.enable true;
  services.jenkins.extraGroups = lib.optionals config.jenkins-nix-ci.features.docker.enable [ "docker" ];
}
