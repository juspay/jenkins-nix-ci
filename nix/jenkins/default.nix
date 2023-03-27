{ jenkinsPlugins2nix }:
{ flake, pkgs, lib, config, ... }:

let
  enabledFeatures = lib.filterAttrs (n: v: v.enable) config.jenkins-nix-ci.features;
  features_packages =
    lib.concatMap (cfg: cfg.node.packages) (lib.attrValues enabledFeatures);
in
{
  imports = [
    ./casc.nix
  ];
  options.jenkins-nix-ci = lib.mkOption {
    type = lib.types.submoduleWith {
      shorthandOnlyDefinesConfig = true;
      specialArgs = {
        inherit pkgs lib;
        inherit (config.sops) secrets;
      };
      modules = [
        ./features
        {
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
            plugins = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "A list of plugins to install.";
            };
            plugins-file = lib.mkOption {
              type = lib.types.str;
              default = null;
              description = ''
                Path to the generated Nix expression containing the plugins.

                Must be relative to project root.
              '';
            };
            nix-prefetch-jenkins-plugins = lib.mkOption {
              type = lib.types.functionTo lib.types.package;
              default = pkgs:
                let
                  jenkinsPlugins2nix_system =
                    if pkgs.system == "aarch64-darwin" then "x86_64-darwin" else pkgs.system;
                  fetcher = jenkinsPlugins2nix.packages.${jenkinsPlugins2nix_system}.jenkinsPlugins2nix;
                  inherit (config.jenkins-nix-ci) plugins;
                in
                pkgs.writeShellApplication {
                  name = "nix-prefetch-jenkins-plugins";
                  text = ''
                    ${lib.getExe fetcher} \
                      ${lib.foldl (a: b: "${a} -p ${b}") "" plugins}
                  '';
                };
              description = ''
                The program that creates `plugins.nix` based on given plugins.

                This will fetch the latest plugins using jenkinsPlugins2Nix.
              '';
            };
          };
        }
      ];
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
        # Add packages used by Jenkins plugins here.
        git
        bash # 'sh' step requires this
        coreutils
        which
        nix
      ] ++ features_packages;
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

    # The following configuration will be moved to slaves when we have them.

    # To allow the local node to run as builder, supporting nix builds.
    # This should not be necessary with external build agents.
    nix.settings.allowed-users = [ "jenkins" ];
    nix.settings.trusted-users = [ "jenkins" ];

    # Install docker so we can build images.
    virtualisation.docker.enable = lib.mkIf config.jenkins-nix-ci.features.docker.enable true;
    services.jenkins.extraGroups = lib.optionals config.jenkins-nix-ci.features.docker.enable [ "docker" ];
  };
}
