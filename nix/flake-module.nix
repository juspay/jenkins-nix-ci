{ inputs, config, lib, flake-parts-lib, ... }:

let
  inherit (flake-parts-lib)
    mkPerSystemOption;
  inherit (lib)
    mkOption
    types;
in
{
  options =
    let
      topModule = types.submodule {
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
        };
      };
    in
    {
      jenkins-nix-ci = mkOption {
        type = topModule;
        default = { };
        description = ''
          Jenkins Nix CI configuration.
        '';
      };
      perSystem = mkPerSystemOption
        (perSystem@{ pkgs, system, ... }: {
          config.packages.update-plugins =
            let
              jenkinsPlugins2nix_system =
                if system == "aarch64-darwin" then "x86_64-darwin" else system;
              jenkinsPlugins2nix = inputs.jenkinsPlugins2nix.packages.${jenkinsPlugins2nix_system}.jenkinsPlugins2nix;
              inherit (config.jenkins-nix-ci) plugins plugins-file;

            in
            pkgs.writeShellApplication {
              name = "update-plugins";
              text = ''
                ${lib.getExe perSystem.config.flake-root.package}
                set -x
                ${lib.getExe jenkinsPlugins2nix} \
                  ${lib.foldl (a: b: "${a} -p ${b}") "" plugins} \
                  > ${plugins-file}
              '';
            };
        });

      flake = mkOption {
        type = types.submoduleWith {
          modules = [{
            config = {
              nixosModules.jenkins-master = ./jenkins.nix;
            };
          }];
        };
      };
    };
}
