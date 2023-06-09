{ pkgs, lib, config, ... }:

{
  imports = [
    ./cachix
    ./docker
    ./githubApp
    ./nix
    ./ssh-key
  ];

  options.feature-outputs = {
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
    node.nixosConfiguration = lib.mkOption {
      type = lib.types.listOf lib.types.deferredModule;
      internal = true;
    };
    node.darwinConfiguration = lib.mkOption {
      type = lib.types.listOf lib.types.deferredModule;
      internal = true;
    };
  };
  config.feature-outputs =
    let
      enabledFeatures = lib.filterAttrs (n: v: v.enable) config.features;
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
      node.nixosConfiguration = lib.forEach (lib.attrValues enabledFeatures) (cfg: cfg.node.nixosConfiguration);
      node.darwinConfiguration = lib.forEach (lib.attrValues enabledFeatures) (cfg: cfg.node.darwinConfiguration);
    };
}
