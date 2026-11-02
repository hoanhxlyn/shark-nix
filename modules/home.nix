{
  pkgs,
  lib,
  ...
}: let
  shark = pkgs.callPackage ../package.nix {};
in {
  home.packages = [shark];
  # Same idea as solaarDpi: two stages (default 1400, button toggles 1600) back on every login,
  # including the disabled stages 3..8 the GUI may have left enabled. static_dpi keeps the LED
  # on and shows which stage is active, instead of the "off" the GUI leaves behind.
  # The firmware sleeps after 1 min, which swallows the first move; the GUI resets it too.
  home.activation.attackShark = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${shark}/bin/x11ctl dpi --stages 1400,1600 --active 1 --colors '#4cd964,#ff0000' >/dev/null 2>&1 || true
    ${shark}/bin/x11ctl light --mode static_dpi --brightness 3 >/dev/null 2>&1 || true
    ${shark}/bin/x11ctl power --sleep 15 --deep-sleep 60 >/dev/null 2>&1 || true
  '';
  home.file.".local/share/applications/attack-shark.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=ATTACK SHARK X11SE
    Comment=DPI stages, polling, buttons, lighting and battery
    Exec=${shark}/bin/x11gui
    Icon=input-mouse
    Categories=Utility;Settings;
  '';
}
