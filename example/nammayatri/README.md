
# nammayatri Jenkins CI

Configuration for the CI machine used in https://github.com/nammayatri

## Deploying

```sh
./deploy.sh
```

## Local build

```sh
nix build .#nixosConfigurations.jenkins-nix-ci.config.system.build.toplevel
```

