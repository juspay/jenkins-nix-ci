{ pkgs, ... }:

# ./groovy-library in a Git repo.
pkgs.runCommand "jenkins-nix-ci-library"
{
  buildInputs = [ pkgs.git ];
}
  ''
    mkdir -p $out
    cp -r ${./.}/* $out
    cd $out
    git init
    git add .
    git config user.email "nobody@localhost"
    git config user.name "github:juspay/jenkins-nix-ci"
    git commit -m "Added by pkgs.runCommand"
  ''
