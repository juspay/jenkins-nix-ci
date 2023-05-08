# jenkins-nix-ci

A [NixOS module][nixos-mod] to run [Jenkins][jenkins], optimized specifically for running projects using [Nix].

![image](https://user-images.githubusercontent.com/3998/231465854-f2b8d5ab-500a-446d-9dfd-1ea3688b3828.png)

## Features

- Fully nixified
    - [x] Jenkins configuration declared in Nix (via [configuration-as-code](https://github.com/jenkinsci/configuration-as-code-plugin) plugin)
    - [x] [sops-nix] for secrets management, for use in Jenkins credentials. Known limitation: only JSON format is supported.
    - [x] Jenkins plugins are managed by [jenkinsPlugins2nix](https://github.com/Fuuzetsu/jenkinsPlugins2nix)
- CI features as NixOS modules, encapsulated along with their associated groovy library for referencing in `Jenkinsfile`
    - [x] [cachix](https://www.cachix.org/): provides `cachixPush` and `cachixUse` pipeline steps
    - [x] [docker](https://www.docker.com/): provides `dockerPush` pipeline step
    - [x] `githubApp`: provides Github integration for CI status reporting
    - [x] `nix`: provides `nixBuildAll` to build all flake outputs
      - Uses `--no-update-lock-file` (thus fails on out of sync `flake.lock` files)

### What's to come

- [x] Isolated Linux build agents (as [NixOS containers](https://nixos.wiki/wiki/NixOS_Containers) on local machine)
- [ ] External macOS build agent
    

## Examples

- [./example/nammayatri](./example/nammayatri/flake.nix) (used in https://github.com/nammayatri/nammayatri)
- https://github.com/srid/nixos-config/blob/master/nixos/jenkins.nix (used in https://github.com/srid/emanote, https://github.com/srid/haskell-flake, etc.)

## Plugins

To update the plugins, run `nix-prefetch-jenkins-plugins > nix/jenkins/plugins.nix`. `nix-prefetch-jenkins-plugins` must have been added to the devShell. See the aforementioned example.

## Secrets

We use [sops-nix] to manage secrets used by the individual CI features. Convert your SSH key (ed25519) to age, which sops uses. With macOS & 1Password, it would look like:

```sh
nix run nixpkgs#ssh-to-age  <<< "$(op read 'op://Personal/id_ed25519/public key')"
nix run nixpkgs#ssh-to-age -- --private-key -i <(op read 'op://Personal/id_ed25519/actual private') > ~/.config/sops/age/keys.txt
# ^ $HOME/Library/Application\ Support/sops/age/keys.txt actually
```

You also want to get the host key (`ssh-keyscan localhost | ssh-to-age`) of the machine being deployed.

Put both these public age keys in `.sops.yaml` of the repository.


[sops-nix]: https://github.com/Mic92/sops-nix
[nixos-mod]: https://nixos.wiki/wiki/NixOS_modules
[jenkins]: https://www.jenkins.io/
[Nix]: https://zero-to-nix.com/
