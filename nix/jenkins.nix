{ flake, pkgs, config, ... }:

{
  imports = [
    ./jenkins/casc.nix
  ];
  config = {
    services.jenkins = {
      enable = true;
      inherit (flake.config.jenkins-nix-ci) port;
      environment = {
        CASC_JENKINS_CONFIG =
          builtins.toString (pkgs.writeText "jenkins.json" (builtins.toJSON config.jenkins-nix-ci.cascConfig));
      };
      packages = with pkgs; [
        # Add packages used by Jenkins plugins here.
        git
        bash # 'sh' step requires this
        coreutils
        which
        nix
        docker

        # Groovy library packages
        cachix
        (pkgs.callPackage ../groovy-library/vars/cachixPush.nix { inherit pkgs; })
        (pkgs.callPackage ../groovy-library/vars/dockerPush.nix { inherit pkgs; })
      ];
      plugins = import "${flake.self}/${flake.config.jenkins-nix-ci.plugins-file}" {
        inherit (pkgs) fetchurl stdenv;
      };
      extraJavaOptions = [
        # Useful when the 'sh' step b0rks.
        # https://stackoverflow.com/a/66098536/55246
        "-Dorg.jenkinsci.plugins.durabletask.BourneShellScript.LAUNCH_DIAGNOSTICS=true"
        # To allow referencing local libraries in the /nix store. ie., our /groovy-library.
        "-Dhudson.plugins.git.GitSCM.ALLOW_LOCAL_CHECKOUT=true"
      ];
    };

    # The following configuration will be moved to slaves when we have them.

    # To allow the local node to run as builder, supporting nix builds.
    # This should not be necessary with external build agents.
    nix.settings.allowed-users = [ "jenkins" ];
    nix.settings.trusted-users = [ "jenkins" ];

    # Install docker so we can build images.
    virtualisation.docker.enable = true;
    services.jenkins.extraGroups = [ "docker" ];
  };
}
