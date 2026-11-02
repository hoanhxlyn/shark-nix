# shark-nix

Nix flake for the **ATTACK SHARK X11 / X11SE** gaming mouse. It packages
[attackshark-x11-linux](https://github.com/MiguelSanzBr/attackshark-x11-linux) and makes its settings
declarative through NixOS and Home Manager.

- `packages.default` — `x11ctl` (CLI) and `x11gui` (Tk GUI): DPI stages, polling, buttons, lighting,
  sleep timers, battery.
- `packages.shark-battery` — battery percentage only.
- `nixosModules.default` — udev rules for the receiver and both cable modes, plus the hotplug trigger.
- `homeManagerModules.default` — `programs.sharkx11` options, the apps, a desktop entry, and a user
  service that applies the declared settings.

Only `x86_64-linux` is exposed.

## Quick start

```nix
{
  inputs.shark-nix.url = "github:hoanhxlyn/shark-nix";
}
```

NixOS with Home Manager:

```nix
{
  imports = [inputs.shark-nix.nixosModules.default];

  home-manager.users.you = {
    imports = [inputs.shark-nix.homeManagerModules.default];

    programs.sharkx11 = {
      enable = true;

      dpi.stages = [
        {dpi = 1400; color = "#4cd964";}
        {dpi = 1600; color = "#ff0000";}
      ];
      dpi.activeStage = 1;

      pollingRate = 1000;
      lighting = {mode = "static_dpi"; color = "#4cd964"; brightness = 3;};
      power = {sleep = 15; deepSleep = 60;};

      buttons.forward = "key:ctrl+shift+t";
    };
  };
}
```

The defaults are the app's factory settings, so `enable = true` alone changes nothing.

| Option | Values |
| --- | --- |
| `dpi.stages` | 1–8 `{dpi; color;}` entries, in stage order |
| `dpi.activeStage` | index of the stage selected at power-on |
| `dpi.angleSnap`, `dpi.ripple` | booleans |
| `pollingRate` | `125`, `250`, `500`, `1000` |
| `lighting.mode` | `off`, `static`, `breathing`, `neon`, `color_breathing`, `static_dpi`, `breathing_dpi` |
| `lighting.color`, `lighting.brightness` (1–8), `lighting.speed` (1–5) | |
| `power.sleep`, `power.deepSleep` | minutes, 1–60 |
| `power.debounce` | milliseconds, 2–25 |
| `buttons.left/right/middle/forward/back` | an action from `x11ctl actions`, or `key:<mods+key>` |
| `package` | override the packaged app |

## How settings are applied

DPI, polling, lighting and power live in the mouse firmware, so the module pushes them. The NixOS
module tags the mouse's hidraw nodes; the `sharkx11-apply` user service runs when the mouse is plugged
in and at login, and writes everything in one connection.

The button map is the only setting kept in a file, because the mouse cannot report it back.
`~/.config/sharkx11/buttons.json` is a read-only symlink generated from Nix, so changing buttons in
the GUI edits the mouse but cannot persist — change the options instead.

Standalone Home Manager (without the NixOS module) has no udev rules: install
`udev/70-attackshark-x11.rules` from upstream yourself, and the service will only apply at login.

## Without Home Manager

```bash
nix run github:hoanhxlyn/shark-nix                 # x11gui
nix shell github:hoanhxlyn/shark-nix -c x11ctl info
```

Add `packages.shark-battery` to use it in a Waybar module:

```json
"custom/mouse": {
  "exec": "shark-battery",
  "return-type": "text",
  "interval": 60
}
```

## Updating the pinned app

Edit `rev` in `package.nix`, run `nix build`, paste the hash from the error, and update `version` to
the value in upstream's `pyproject.toml` (currently `0.1.0b4`, while the tag is `v0.1.0-beta.4`).
