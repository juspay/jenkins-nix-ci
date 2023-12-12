# jenkins-nix-ci

A [NixOS module][nixos-mod] to run [Jenkins][jenkins], optimized specifically for running projects using [Nix].

## Features

- Fully nixified
    - [x] Jenkins configuration declared in Nix (via [configuration-as-code](https://github.com/jenkinsci/configuration-as-code-plugin) plugin)
    - [x] [sops-nix] for secrets management, for use in Jenkins credentials. Known limitation: only JSON format is supported.
    - [x] Jenkins plugins are managed by [jenkinsPlugins2nix](https://github.com/Fuuzetsu/jenkinsPlugins2nix)
- Isolated build agents
    - [x] [NixOS containers](https://nixos.wiki/wiki/NixOS_Containers) as build agents (runs in local node)
    - [x] External SSH slaves (useful to run macOS build nodes)
- CI features as NixOS modules, encapsulated along with their associated groovy library for referencing in `Jenkinsfile`
    - [x] `nix`: provides `nixCI` (using [nixci](https://github.com/srid/nixci)) to build all flake outputs, and sets `env.FLAKE_OUTPUTS` to the list of outputs built.
        - Uses `--no-update-lock-file` (thus fails on out of sync `flake.lock` files)
        - Supports sub flakes ([example](https://github.com/srid/haskell-flake/pull/179)) via `nixci`
    - [x] [cachix](https://www.cachix.org/): provides `cachixPush` and `cachixUse` pipeline steps
        - `cachixPush` will push the `env.FLAKE_OUTPUTS` built by the `nix` feature
    - [x] [docker](https://www.docker.com/): provides `dockerPush` pipeline step
    - [x] `githubApp`: provides Github integration for CI status reporting

## Examples

- https://github.com/nammayatri/jenkins-config (used by [Nammayatri](https://www.nammayatri.in/))
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

## Discussion

- [Zulip](https://nixos.zulipchat.com/#narrow/stream/416818-jenkins-nix-ci)

[sops-nix]: https://github.com/Mic92/sops-nix
[nixos-mod]: https://nixos.wiki/wiki/NixOS_modules
[jenkins]: https://www.jenkins.io/
[Nix]: https://zero-to-nix.com/
