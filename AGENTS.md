# shark-nix

Nix flake that packages [attackshark-x11-linux](https://github.com/MiguelSanzBr/attackshark-x11-linux)
(`x11ctl`/`x11gui` for the ATTACK SHARK X11/X11SE mouse) and ships NixOS/Home Manager modules for it.
The Python app itself is **not** in this repo; it is pinned by commit in `package.nix`.

## Commands

```bash
nix build .#default .#shark-battery   # the only "tests"; there is no test suite
nix flake check                       # does NOT evaluate the NixOS/HM modules
nix develop -c alejandra --check .    # Nix formatting
nix develop -c statix check .         # Nix lint
nix develop -c deadnix --no-lambda-pattern-names .
```

Module changes need a throwaway evaluation: build the udev rules with `lib.nixosSystem`, or evaluate
`homeManagerConfiguration` against `github:nix-community/home-manager` (Home Manager is not a flake
input here, so there is no `nix build` target for the HM module).

For `scripts/*.py`, test against a fake `sharkx11.device.Device`; never write settings to the real
mouse. The scripts import `sharkx11` through `PYTHONPATH` pointing at the built package's
`lib/python3.*/site-packages` (same pattern as `shark-battery` in `flake.nix`).

## Domain invariants

- Only `~/.config/sharkx11/buttons.json` is a local settings file. DPI, polling, lighting, sleep and
  debounce live in the mouse firmware, so the HM module pushes them (`scripts/apply.py`) on udev
  events and at login. Don't look for a config file for those.
- `buttons.json` is an 18-slot list; only 5 slots are remappable (`config.BUTTONS`). Shortcuts are
  stored as `["key", mods, usage]`, not `"key:..."`; the `"key:..."` string form is what the Nix
  options take. The app refuses any map without a left click.
- `modules/home.nix` generates `settings.json` and `apply.py` consumes it. Renaming a key requires
  editing both. `buttons.py` validates actions/shortcuts at build time using the package's parser.
- The user unit name `sharkx11-apply.service` in `modules/home.nix` must match
  `ENV{SYSTEMD_USER_WANTS}` in `modules/nixos.nix`.
- The udev rules are product-scoped on purpose (`1d57:fa60` receiver, `fa55` X11 wired, `2125`
  X11SE wired), and must stay `70-*`: systemd's `73-seat-late.rules` turns `uaccess` into an ACL.
- The GUI writes `buttons.json` itself; it is a read-only store symlink, so GUI/CLI button edits
  change the mouse but fail to persist. That is the point of the immutable config.
- `doCheck = false` is deliberate; upstream's 93 tests pass under `xvfb-run` but are not wired up.
- Keep `python3Packages.tkinter` in `propagatedBuildInputs`: nixpkgs `python3` has no `_tkinter` and
  the GUI entry point (`mainProgram = "x11gui"`) is what the package is for.

## Updating the pin

Bump `rev` in `package.nix`, run `nix build`, paste the hash from the mismatch, and set `version` to
the upstream `pyproject.toml` value (`0.1.0b4`, while the tag is `v0.1.0-beta.4`). The pinned commit
is not the tag commit. `fetchFromGitHub` supplies the same tarball as the old `fetchzip`, so the
hash does not change when only the fetcher is swapped.

## Nix gotchas hit in this repo

- Nix has no `%`; use `lib.mod`.
- `lib.mkPackageOption`'s `default` takes an attr path string, not a derivation; use `lib.mkOption`
  for `programs.sharkx11.package`.
- `lib.evalModules` does not run `assertions`; only full NixOS/Home Manager evaluations do.
