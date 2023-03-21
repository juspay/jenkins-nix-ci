{ inputs, ... }:

{
  perSystem = { pkgs, lib, system, config, ... }: {
    packages.update-plugins =
      let
        jenkinsPlugins2nix_system =
          if system == "aarch64-darwin" then "x86_64-darwin" else system;
        jenkinsPlugins2nix = inputs.jenkinsPlugins2nix.packages.${jenkinsPlugins2nix_system}.jenkinsPlugins2nix;
        plugins = [
          "github-api"
          "git"
          "github-branch-source"
          "workflow-aggregator"
          "ssh-slaves"
          "configuration-as-code"
        ];
      in
      pkgs.writeShellApplication {
        name = "update-plugins";
        text = ''
          ${lib.getExe config.flake-root.package}
          set -x
          ${lib.getExe jenkinsPlugins2nix} \
            ${lib.foldl (a: b: "${a} -p ${b}") "" plugins} \
            > nix/jenkins/plugins/default.nix
        '';
      };
  };
}

