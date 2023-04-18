{ flake, jenkinsPlugins2nix, pkgs, lib, config, ... }:

{
  imports = [
    ./casc.nix
    ./nodes.nix
  ];

  options.jenkins-nix-ci = lib.mkOption {
    description = "Jenkins master configuration";
    type = lib.types.submoduleWith {
      shorthandOnlyDefinesConfig = true;
      specialArgs = {
        inherit pkgs lib;
        inherit jenkinsPlugins2nix;
        inherit (config) sops;
        inherit (config.services) jenkins;
        cascLib = pkgs.callPackage ./casc/lib.nix { };
      };
      modules = [{
        imports = [
          ./plugins.nix
          ./features
        ];
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
        CASC_JENKINS_CONFIG = lib.pipe config.jenkins-nix-ci.cascConfig [
          builtins.toJSON
          (pkgs.writeText "jenkins.json")
          builtins.toString
        ];
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
