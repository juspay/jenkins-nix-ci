{ pkgs, ... }:

pkgs.writeShellApplication {
  name = "jenkins-nix-ci-dockerPush";
  runtimeInputs = [ pkgs.jq ];
  text = ''
    set -euo pipefail


    set -x
    # Do a git status, because the docker tag is based on working copy status
    git status
    docker load -i "$(nix build ".#$1" --print-out-paths --no-update-lock-file)"
    set +x
    IMAGE_NAME="$(nix eval --json .#packages.x86_64-linux."$1".buildArgs | jq -r '"\(.name):\(.tag)"')"
    echo "Built and loaded: ''${IMAGE_NAME}"

    echo "Logging in to Docker Registry"

    # Use a temp directory as $HOME, because 'docker login' stores the
    # password insecurely.
    HOME="$(mktemp -d)"
    export HOME
    trap 'rm -rf "$HOME"'  EXIT

    echo "''${DOCKER_PASS}" | docker login -u "''${DOCKER_USER}" --password-stdin "''${DOCKER_SERVER}"
    set -x
    docker push "''${IMAGE_NAME}"
    set +x
    docker logout "''${DOCKER_SERVER}"
  '';
}
