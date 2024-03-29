{ pkgs, lib, config, ... }:

let
  containerSlaves = config.jenkins-nix-ci.nodes.containerSlaves;

  nodeSubModule = defaults: lib.types.submoduleWith {
    modules = [
      defaults
      {
        options = {
          hostIP = lib.mkOption {
            type = lib.types.str;
            description = "IP address of the node";
          };
          numExecutors = lib.mkOption {
            type = lib.types.int;
            description = "Number of executors for this node";
          };
          labelString = lib.mkOption {
            type = lib.types.str;
            description = "Node label string (referenced in Jenkinsfile)";
          };
        };
      }
    ];
  };
in
{
  options = {
    jenkins-nix-ci.nodes = lib.mkOption {
      type = lib.types.submodule {
        options = {
          sshSlaves = lib.mkOption {
            default = { };
            type = lib.types.attrsOf (nodeSubModule { });
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
                max-jobs = lib.mkOption {
                  type = lib.types.either lib.types.int (lib.types.enum [ "auto" ]);
                  description = ''
                    Maximum number of jobs to run on each container.

                    You should set this to a reasonable number: `nproc --all`
                    divided by the number of containers.
                  '';
                  default = "auto";
                };
                containers = lib.mkOption {
                  type = lib.types.attrsOf (nodeSubModule {
                    numExecutors = lib.mkDefault 1;
                    labelString = lib.mkDefault "nixos linux ${pkgs.system} ${if pkgs.system == "x86_64-linux" then "aarch64-linux" else ""}";
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
        config = import ./slave/nixos-container.nix { inherit config; }; 
      });
  };
}
