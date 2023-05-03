# DRY: with jenkins-nix-ci
{ flake, pkgs, ... }:

# Two manual steps required:
# - authorize keys manually
# - allow macos to accept ssh connections for this user: https://superuser.com/a/445814
#   > dscl . change /Groups/com.apple.access_ssh RecordName com.apple.access_ssh com.apple.access_ssh-disabled
{
  users.knownUsers = [ "jenkins" ];
  # FIXME: nix-darwin has no way to set authorized_keys
  # https://github.com/LnL7/nix-darwin/issues/562
  # we must manually do it! 
  users.users.jenkins = {
    home = "/var/lib/jenkins";
    uid = 987;
    createHome = true;
    shell = "/bin/bash";
  };

  # TODO: The below configuration violates DRY. We should ideally use the
  # 'features' module (and the feature-outputs' node.config) here.
  
  environment.systemPackages = with pkgs; [
    bashInteractive
    cachix
    devour-flake
    (pkgs.callPackage ../../../../nix/jenkins/features/cachix/cachixPush.nix {})
  ];

  # TODO: Consolidate with the overlay in top-level flake
  nixpkgs.overlays = [
    (self: super: {
      cachix = flake.inputs.jenkins-nix-ci.inputs.cachix.packages.${pkgs.system}.default;
      devour-flake = self.callPackage flake.inputs.jenkins-nix-ci.inputs.devour-flake { };
    })
  ];

  nix.settings = {
    allowed-users = [ "jenkins" ];
    trusted-users = [ "jenkins" ];
  };

  home-manager.users.jenkins = {
    # Because, the ssh-slaves plugin looks for java under ~/jdk
    # https://github.com/jenkinsci/ssh-slaves-plugin/blob/8ecb84077797fb4eedd72942a4791e61955a50fd/src/main/java/hudson/plugins/sshslaves/DefaultJavaProvider.java#L65
    home.file."jdk".source = pkgs.jdk;

    home.stateVersion = "22.11";
  };
}
