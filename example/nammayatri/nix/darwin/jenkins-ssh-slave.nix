# DRY: with jenkins-nix-ci
{ pkgs, ... }:

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

  environment.systemPackages = with pkgs; [
    # TODO: Must use features' packages
    jdk11
    bashInteractive
    cachix
  ];

  nix.settings = {
    allowed-users = [ "jenkins" ];
    trusted-users = [ "jenkins" ];
  };
}
