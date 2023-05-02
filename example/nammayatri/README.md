
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

## Local build

For linux,

```sh
nix build .#nixosConfigurations.jenkins-nix-ci.config.system.build.toplevel
```

