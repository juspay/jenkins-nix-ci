{ config, cascLib, sops, jenkins, lib, ... }:

let
  types = lib.types;
in
{
  options.features.ssh-key = {
    enable = lib.mkOption {
      type = types.bool;
      # Always enabled, because ssh key is used to connect to the slave nodes
      default = true;
      internal = true;
      readOnly = true;
    };

    sopsSecrets = lib.mkOption {
      type = types.listOf types.str;
      readOnly = true;
      default = [
        "jenkins-nix-ci/ssh-key/private"
        "jenkins-nix-ci/ssh-key/public_unencrypted"
      ];
    };

    casc.credentials = lib.mkOption {
      type = types.listOf types.attrs;
      readOnly = true;
      default = [
        {
          basicSSHUserPrivateKey = {
            id = "ssh-private-key";
            username = jenkins.user;
            description = "SSH key used by Jenkins master to talk to slaves";
            privateKeySource.directEntry.privateKey =
              cascLib.readFile
                sops.secrets."jenkins-nix-ci/ssh-key/private".path;
          };
        }
      ];
    };

    sharedLibrary = lib.mkOption {
      type = types.nullOr types.package;
      readOnly = true;
      default = null;
    };

    node.nixosConfiguration = lib.mkOption {
      type = types.deferredModule;
      readOnly = true;
      default =
        let
          authorizedKey =
            let
              secretsRaw = assert (sops.defaultSopsFormat == "json"); builtins.fromJSON (builtins.readFile sops.defaultSopsFile);
            in
            secretsRaw.jenkins-nix-ci.ssh-key.public_unencrypted;
        in
        {
          users.users.${jenkins.user}.openssh.authorizedKeys.keys = [ authorizedKey ];
        };
    };

    node.darwinConfiguration = lib.mkOption {
      type = types.deferredModule;
      readOnly = true;
      default = config.features.ssh-key.node.nixosConfiguration;
    };
  };
}
