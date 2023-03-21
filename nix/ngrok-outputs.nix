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
