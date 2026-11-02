# shark-nix

Nix flake for the **ATTACK SHARK X11 / X11SE** gaming mouse.

- `packages.default` — [attackshark-x11-linux](https://github.com/MiguelSanzBr/attackshark-x11-linux) packaged:
  `x11ctl` CLI and `x11gui` Tk configurator (DPI, polling, buttons, lighting, battery, sleep timers)
- `packages.shark-battery` — prints the battery percentage, read from the mouse's own heartbeat
  (input report `0x03`), so it never sends a settings request that would stall pointer motion
- `nixosModules.default` — udev rule granting the logged-in user access to the dongle's `/dev/hidraw*`
- `homeManagerModules.default` — installs the CLI/GUI, a desktop entry, and reapplies the preferred
  DPI stages, LED brightness and sleep timers at login

## Usage

```nix
{
  inputs.shark-nix.url = "github:hoanhxlyn/shark-nix";

  # NixOS
  imports = [inputs.shark-nix.nixosModules.default];

  # Home Manager
  imports = [inputs.shark-nix.homeManagerModules.default];
}
```

Waybar battery module:

```json
"custom/mouse": {
  "exec": "shark-battery",
  "return-type": "text",
  "interval": 60
}
```

## Updating

Bump the commit in `package.nix`, then `nix build` and paste the hash it reports.

## License

MIT
