# Test new modules in a VM

Shamelessly stolen from: https://nixos.wiki/wiki/Nixpkgs/Reviewing_changes#Modules

- Add module to test (see comments)
- run `nix run`

When the fork/branch being testet is updated, update the `flake.lock` input
using `nix run --update-input pkgsReview`
