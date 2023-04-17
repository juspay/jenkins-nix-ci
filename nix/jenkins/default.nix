{ flake, flake-outputs, cachix-master, pkgs, lib, config, ... }:

{
  imports = [
    ./casc.nix
    ./nodes.nix
    ./plugins.nix
  ];

  options.jenkins-nix-ci = lib.mkOption {
    type = lib.types.submoduleWith {
      shorthandOnlyDefinesConfig = true;
      specialArgs = {
        inherit flake-outputs cachix-master;
        inherit (config.services) jenkins;
        inherit (config) sops;
        inherit (config.jenkins-nix-ci) cascLib;
        inherit pkgs lib;
      };
      modules = [{
        imports = [ ./features ];
        options = {
          port = lib.mkOption {
            type = lib.types.int;
            default = 9091;
            description = "The port to run Jenkins on.";
          };
          domain = lib.mkOption {
            type = lib.types.str;
            description = "The domain in which Jenkins is exposed to the outside world.";
          };
        };
      }];
    };
  };

  config = {
    services.jenkins = {
      enable = true;
      inherit (config.jenkins-nix-ci) port;
      environment = {
        CASC_JENKINS_CONFIG =
          builtins.toString (pkgs.writeText "jenkins.json" (builtins.toJSON config.jenkins-nix-ci.cascConfig));
      };
      packages = with pkgs; [
        git
        bash # 'sh' step requires this
        coreutils
        which
      ];
      plugins = import "${flake.self}/${config.jenkins-nix-ci.plugins-file}" {
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
  };
}
