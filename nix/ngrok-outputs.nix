# TODO: This should be combined with ngrok.nix as a nice flake-parts module with
# options.
{ self, ... }:

{
  perSystem = { pkgs, lib, ... }: {
    apps = {
      # SSH to the machine
      ssh = {
        type = "app";
        program =
          let
            inherit (self.deploy.nodes.jenkins-nix-ci) sshOpts sshUser hostname;
          in
          lib.getExe (pkgs.writeShellApplication {
            name = "ssh-jenkins-nix-ci";
            text = ''
              ssh ${lib.concatStringsSep " " sshOpts} ${sshUser}@${hostname}
            '';
          });
      };

      hostkey = {
        type = "app";
        program =
          let
            inherit (self.deploy.nodes.jenkins-nix-ci) sshOpts sshUser hostname;
          in
          lib.getExe (pkgs.writeShellApplication {
            name = "hostkey-jenkins-nix-ci";
            runtimeInputs = [ pkgs.ssh-to-age ];
            text = ''
              ssh-keyscan ${lib.concatStringsSep " " sshOpts} ${sshUser}@${hostname} | \
                ssh-to-age
            '';
          });
      };

      # Exposes Jenkins service in http://localhost:8081
      # (Also drops you into the SSH session)
      port-forward = {
        type = "app";
        program =
          let
            inherit (self.deploy.nodes.jenkins-nix-ci) sshOpts sshUser hostname;
          in
          lib.getExe (pkgs.writeShellApplication {
            name = "ssh-jenkins-nix-ci";
            text = ''
              set -x
              ssh ${lib.concatStringsSep " " sshOpts} \
                -L 127.0.0.1:9091:localhost:9091 \
                ${sshUser}@${hostname}
            '';
          });
      };
    };
  };
}
