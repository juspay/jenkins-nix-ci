{ pkgs, lib, config, ... }:

{
  options = {
    # TODO: The should include 'features' plugins as well.
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
      type = lib.types.package;
      default = pkgs.writeShellApplication {
        name = "nix-prefetch-jenkins-plugins";
        text = ''
          ${lib.getExe pkgs.jenkinsPlugins2Nix} \
            ${lib.foldl (a: b: "${a} -p ${b}") "" config.plugins}
        '';
      };
      description = ''
        The program that creates `plugins.nix` based on given plugins.

        This will fetch the latest plugins using jenkinsPlugins2Nix.
      '';
    };
  };
}
