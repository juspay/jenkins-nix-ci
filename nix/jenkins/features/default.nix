{ pkgs, lib, config, ... }:

{
  imports = [
    ./cachix
    ./docker
    ./githubApp
  ];

  options.jenkins-nix-ci.feature-outputs = {
    sopsSecrets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      internal = true;
    };
    casc.credentials = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      internal = true;
    };
    sharedLibrary = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
    };
    node.packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      internal = true;
    };
  };
  config.jenkins-nix-ci.feature-outputs =
    let
      enabledFeatures = lib.filterAttrs (n: v: v.enable) config.jenkins-nix-ci.features;
    in
    {
      sopsSecrets = lib.concatMap (cfg: cfg.sopsSecrets) (lib.attrValues enabledFeatures);
      casc.credentials = lib.concatMap (cfg: cfg.casc.credentials) (lib.attrValues enabledFeatures);
      sharedLibrary =
        let
          sharedLibraries = lib.concatMap
            (cfg: if cfg.sharedLibrary == null then [ ] else [ cfg.sharedLibrary ])
            (lib.attrValues enabledFeatures);
        in
        pkgs.buildEnv {
          name = "jenkins-nix-ci-library-enabled-features";
          # Just merge the individual libraries, because we expect them to have
          # `./vars` only.
          paths = sharedLibraries;
        };
      node.packages = lib.concatMap (cfg: cfg.node.packages) (lib.attrValues enabledFeatures);
    };
}
