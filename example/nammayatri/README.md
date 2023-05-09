
# nammayatri Jenkins CI

Configuration for the CI machine used in https://github.com/nammayatri

## Deploying

```sh
./deploy.sh
```

To deploy only a single node,

```sh
./deploy.sh .#macos
```

### Initial setup of macOS builder

The nix-darwin module is not fully automated. You must add the Jenkins master's public ssh key (in `secrets.json`) to the builder's "jenkins" users's `.ssh/authorized_keys` file manually.

## Local build

For linux,

```sh
nix build .#nixosConfigurations.jenkins-nix-ci.config.system.build.toplevel
```

