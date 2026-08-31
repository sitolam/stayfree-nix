<div align="center">

# 🧘 stayfree-nix

**[StayFree](https://stayfreeapps.com/) desktop, packaged as a Nix flake** —
screen-time tracking and website blocking on NixOS, with the version bumped
for you.

[![Nix flake](https://img.shields.io/badge/nix-flake-5277C3?style=flat-square&logo=nixos&logoColor=white)](https://nixos.org)
[![x86_64-linux](https://img.shields.io/badge/platform-x86__64--linux-89b4fa?style=flat-square)](#why-x86_64-only)
[![auto-updated daily](https://img.shields.io/badge/updates-daily%20PR-a6e3a1?style=flat-square)](.github/workflows/update.yml)
[![packaging: MIT](https://img.shields.io/badge/packaging-MIT-cba6f7?style=flat-square)](LICENSE)
[![app: unfree](https://img.shields.io/badge/app-unfree-f38ba8?style=flat-square)](#licence)

</div>

## Why this exists

StayFree ships a `.deb` and an AppImage from
[`stayfree-app/desktop-releases`](https://github.com/stayfree-app/desktop-releases)
and nothing else. It is not in nixpkgs — the request has been open since 2024
([NixOS/nixpkgs#338978](https://github.com/NixOS/nixpkgs/issues/338978)) — and
the app does not self-update in a way a read-only Nix store would tolerate
anyway. So the version has to be pinned somewhere, and this repo is that
somewhere.

## Use it

```nix
{
  inputs.stayfree = {
    url = "github:sitolam/stayfree-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
```

Then either take the package straight from the flake:

```nix
environment.systemPackages = [ inputs.stayfree.packages.x86_64-linux.stayfree ];
```

…or apply the overlay, which builds it against **your** nixpkgs instead of this
flake's, so the FHS environment comes out of one closure:

```nix
nixpkgs.overlays = [ inputs.stayfree.overlays.default ];
environment.systemPackages = [ pkgs.stayfree ];
```

StayFree is proprietary, so either way you need
`nixpkgs.config.allowUnfree = true` (or an `allowUnfreePredicate` naming it).

Run it once without installing:

```sh
nix run github:sitolam/stayfree-nix
```

| Output | What it is |
|---|---|
| `packages.x86_64-linux.stayfree` | the wrapped AppImage (also `.default`) |
| `overlays.default` | adds `pkgs.stayfree`, built against your nixpkgs |
| `checks.x86_64-linux.stayfree` | what CI builds on every push |
| `formatter.x86_64-linux` | `nixfmt-tree` |

## How it is built

`appimageTools.wrapType2` around the official AppImage. The Electron runtime,
Chromium and every bundled `.so` come from inside the image; Nix only supplies
the FHS environment around it. That is deliberately less clever than
`autoPatchelf`-ing the `.deb`: nothing has to be re-diagnosed each time upstream
changes a bundled library.

The build also lifts two files out of the image so the app shows up like a
native one — its `.desktop` entry (with `Exec=AppRun` rewritten to the wrapper
in the store) and the 512×512 icon.

`--no-sandbox` is kept from upstream's own desktop entry. The wrapper has no
setuid `chrome-sandbox` helper, and Electron refuses to start without one.

### Why x86_64 only

Upstream builds no other Linux target. A flake that advertised `aarch64-linux`
would only fail at fetch time.

## Updating

Version, URL and hash live in [`src.json`](src.json) — the one file that
changes between releases, in JSON so a shell script can edit it without parsing
Nix. **Never edit it by hand.**

```sh
./update.sh    # rewrites src.json from the newest upstream release
```

[`.github/workflows/update.yml`](.github/workflows/update.yml) runs that daily,
builds the result, and opens a PR only when the build succeeds — so a broken
upstream release never becomes the input your machines pull. Downstream, a
`nix flake update stayfree` is the whole bump.

## Licence

The packaging in this repo is [MIT](LICENSE). **StayFree itself is not covered
by it** — the binary this flake downloads is proprietary and stays under
[upstream's own terms](https://stayfreeapps.com/terms). This repo redistributes
nothing; it points Nix at upstream's own release URL.
