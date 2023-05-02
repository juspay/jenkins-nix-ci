{ flake, pkgs, lib, config, ... }:

let
  containerSlaves = config.jenkins-nix-ci.nodes.containerSlaves;
in
{
  options = {
    jenkins-nix-ci.nodes = lib.mkOption {
      type = lib.types.submodule {
        options = {
          sshSlaves = lib.mkOption {
            default = { };
            type = lib.types.attrsOf (lib.types.submodule ({config, ... }: {
              options = {
                hostIP = lib.mkOption {
                  type = lib.types.str;
                  description = "IP address of the SSH slave";
                };
                numExecutors = lib.mkOption {
                  type = lib.types.int;
                  description = "Number of executors for this SSH slave";
                };
                labelString = lib.mkOption {
                  type = lib.types.str;
                  description = "Jenkins node label string for this SSH slave";
                };
              };
            }));
          };
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
                      hostIP = lib.mkOption {
                        type = lib.types.str;
                        description = "Local address of the container";
                      };
                      numExecutors = lib.mkOption {
                        type = lib.types.int;
                        default = 1;
                        description = "Number of executors for the container";
                      };
                      labelString = lib.mkOption {
                        type = lib.types.str;
                        default = "nixos linux ${pkgs.system}";
                        description = "Jenkins node label string for the container";
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
        localAddress = container.hostIP;
        autoStart = true;
        privateNetwork = true;
        config = {
          _module.args = {
            inherit (config.services) jenkins;
          };
          nixpkgs = { inherit (config.nixpkgs) overlays; };
          imports =
            config.jenkins-nix-ci.feature-outputs.node.config
            ++ [
              ./slave.nix
            ];
          system.stateVersion = config.system.stateVersion;
        };
      });
  };
}
