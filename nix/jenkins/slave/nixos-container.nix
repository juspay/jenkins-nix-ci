# NOTE: The 'config' here is the host machine's config.
{ config }:

{
  _module.args = {
    inherit (config.services) jenkins;
  };
  nixpkgs = { inherit (config.nixpkgs) overlays; };
  imports =
    config.jenkins-nix-ci.feature-outputs.node.nixosConfiguration
    ++ [
      ./nixos.nix
    ];
  system.stateVersion = config.system.stateVersion;
}
