# TODO DRY: with jenkins-nix-ci
{ flake, pkgs, ... }:

# Two manual steps required:
# - authorize keys manually (cf. the note in ssh-key/default.nix)
# - allow macos to accept ssh connections for this user: https://superuser.com/a/445814
#   > dscl . change /Groups/com.apple.access_ssh RecordName com.apple.access_ssh com.apple.access_ssh-disabled
{
  _module.args = {
    # HACK: for features/nix/default.nix
    # Instead can we just use "jenkins" hardcoded everywhere?
    jenkins.user = "jenkins";
  };
  imports = flake.self.nixosConfigurations.jenkins-nix-ci.config.jenkins-nix-ci.feature-outputs.node.darwinConfiguration;

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

  home-manager.users.jenkins = {
    # Because, the ssh-slaves plugin looks for java under ~/jdk
    # https://github.com/jenkinsci/ssh-slaves-plugin/blob/8ecb84077797fb4eedd72942a4791e61955a50fd/src/main/java/hudson/plugins/sshslaves/DefaultJavaProvider.java#L65
    home.file."jdk".source = pkgs.jdk;

    home.stateVersion = "22.11";
  };
}
