{ pkgs, lib, config, ... }:

let
  containerSlaves = config.jenkins-nix-ci.nodes.containerSlaves;
  authorizedKey =
    # In lieu of https://github.com/Mic92/sops-nix/issues/317
    let
      fromYAML = pkgs.callPackage ../from-yaml.nix { };
      sopsJson = fromYAML (builtins.readFile config.sops.defaultSopsFile);
    in
    sopsJson.jenkins-nix-ci.ssh-key.public_unencrypted;
in
{
  options = {
    jenkins-nix-ci.nodes = lib.mkOption {
      type = lib.types.submodule {
        options = {
          # TODO: Remove this, after testing
          local.enable = lib.mkEnableOption "Enable building on the local node";
          containerSlaves = lib.mkOption {
            type = lib.types.submodule {
              options = {
                hostAddress = lib.mkOption {
                  type = lib.types.str;
                  description = "Host IP address of the machine";
                };
                externalInterface = lib.mkOption {
                  type = lib.types.str;
                  description = "External interface of the machine";
                };
                containers = lib.mkOption {
                  type = lib.types.attrsOf (lib.types.submodule {
                    options = {
                      localAddress = lib.mkOption {
                        type = lib.types.str;
                        description = "Local address of the container";
                      };
                    };
                  });
                };
              };
            };
          };
        };
      };
    };
  };
  config = {
    # We probably should let the user to configure this, but for now let's do it
    # ourselves until specific requirements emerge.
    networking.nat = {
      enable = true;
      internalInterfaces = [ "ve-+" ];
      inherit (containerSlaves) externalInterface;
    };

    # Required so container guests (non-root users) can talk to nix-daemon.
    nix.settings = {
      allowed-users = [ config.services.jenkins.user ];
      trusted-users = [ config.services.jenkins.user ];
    };

    containers =
      lib.flip lib.mapAttrs containerSlaves.containers (_name: container: {
        inherit (containerSlaves) hostAddress;
        inherit (container) localAddress;
        autoStart = true;
        privateNetwork = true;
        config = {
          imports =
            config.jenkins-nix-ci.feature-outputs.node.config
            ++ [
              ./slave.nix
            ];
          users.users.${config.services.jenkins.user}.openssh.authorizedKeys.keys = [ authorizedKey ];
          system.stateVersion = config.system.stateVersion;
        };
      });
  };
}
