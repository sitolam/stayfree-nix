# stayfree-nix

Nix flake packaging the [StayFree](https://stayfreeapps.com/) desktop client —
a screen-time tracker and website blocker. Upstream ships a `.deb` and an
AppImage from [`stayfree-app/desktop-releases`](https://github.com/stayfree-app/desktop-releases)
and nothing else; it is not in nixpkgs
([nixpkgs#338978](https://github.com/NixOS/nixpkgs/issues/338978)).

The AppImage is wrapped with `appimageTools.wrapType2`, so the Electron
runtime comes from the image itself and only the FHS environment around it is
Nix's problem. `x86_64-linux` only — upstream builds no other Linux target.

StayFree is proprietary freeware, so the package is marked `unfree` and a
consumer needs `nixpkgs.config.allowUnfree = true`.

## Use

```nix
{
  inputs.stayfree.url = "github:sitolam/stayfree-nix";

  # either take the package directly …
  environment.systemPackages = [ inputs.stayfree.packages.x86_64-linux.stayfree ];

  # … or the overlay, which builds it against your own nixpkgs.
  nixpkgs.overlays = [ inputs.stayfree.overlays.default ];
}
```

## Updating

The version, URL and hash live in `src.json`, and `update.sh` rewrites all
three from the newest upstream release. `.github/workflows/update.yml` runs it
daily, builds the result, and opens a PR when there is something to bump — so
a broken upstream release never lands on `main`. Run `./update.sh` by hand for
an early bump. Never edit `src.json` by hand.

## Licence

The packaging in this repo is MIT (`LICENSE`). StayFree itself is not covered
by it — the binary this flake downloads is proprietary and stays under
[upstream's own terms](https://stayfreeapps.com/terms).
