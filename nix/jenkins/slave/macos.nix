# TODO DRY: with jenkins-nix-ci
{ flake, pkgs, ... }:

# Two manual steps required:
# - authorize keys manually (cf. the note in ssh-key/default.nix)
# - allow macos to accept ssh connections for this user: https://superuser.com/a/445814
#   > dscl . change /Groups/com.apple.access_ssh RecordName com.apple.access_ssh com.apple.access_ssh-disabled
let
  # We pull some common information from Jenkins master's nixosConfiguration
  nixosConfig = flake.self.nixosConfigurations.jenkins-nix-ci.config;
in
{
  _module.args = {
    inherit (nixosConfig.services) jenkins;
  };
  imports = nixosConfig.jenkins-nix-ci.feature-outputs.node.darwinConfiguration;

  users.knownUsers = [ "jenkins" ];
  users.users.jenkins = {
    home = "/var/lib/jenkins";
    uid = 987;
    createHome = true;
    shell = "/bin/bash";
  };

  environment.systemPackages = with pkgs; [
    git
    bash # 'sh' step requires this
    coreutils
    which
  ];

  home-manager.users.${nixosConfig.services.jenkins.user} = {
    # Because, the ssh-slaves plugin looks for java under ~/jdk
    # https://github.com/jenkinsci/ssh-slaves-plugin/blob/8ecb84077797fb4eedd72942a4791e61955a50fd/src/main/java/hudson/plugins/sshslaves/DefaultJavaProvider.java#L65
    home.file."jdk".source = pkgs.jdk;
    home.stateVersion = "22.11";
  };
}
