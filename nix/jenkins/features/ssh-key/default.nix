{ cascLib, sops, jenkins, lib, ... }:

let
  types = lib.types;
in
{
  options.features.ssh-key = {
    enable = lib.mkOption {
      type = types.bool;
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

    node.config = lib.mkOption {
      type = types.deferredModule;
      readOnly = true;
      default = { pkgs, ... }:
        let
          authorizedKey =
            # In lieu of https://github.com/Mic92/sops-nix/issues/317
            let
              fromYAML = pkgs.callPackage ../../../from-yaml.nix { };
              sopsJson = fromYAML (builtins.readFile sops.defaultSopsFile);
            in
            sopsJson.jenkins-nix-ci.ssh-key.public_unencrypted;
        in
        {

          users.users.${jenkins.user}.openssh.authorizedKeys.keys = [ authorizedKey ];
        };
    };
  };
}
