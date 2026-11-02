{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.sharkx11;
  shark = cfg.package;
  python = pkgs.python3;
  pythonSite = "${shark}/lib/python${lib.versions.majorMinor python.version}/site-packages";

  # The 18 slots the mouse stores: the five remappable buttons, then the app's factory defaults
  # (config.DEFAULT_MAP) for the slots its UI and CLI never expose.
  buttons =
    [cfg.buttons.left cfg.buttons.right cfg.buttons.middle "off" "off" "dpi_cycle" cfg.buttons.forward cfg.buttons.back]
    ++ lib.lists.replicate 8 "off"
    ++ ["scroll_up" "scroll_down"];

  # The button map is the only setting the mouse cannot report back, so the app caches it here.
  # Generating it with the package's own parser validates the actions and expands "key:..." shortcuts.
  buttonsFile =
    pkgs.runCommandLocal "sharkx11-buttons.json" {
      nativeBuildInputs = [python];
      PYTHONPATH = pythonSite;
    } ''
      python3 ${../scripts/buttons.py} ${lib.escapeShellArg (builtins.toJSON cfg.buttons)} > $out
    '';

  settingsFile = (pkgs.formats.json {}).generate "sharkx11-settings.json" {
    dpi = {
      stages = map (s: {inherit (s) dpi color;}) cfg.dpi.stages;
      active = cfg.dpi.activeStage;
      angle_snap = cfg.dpi.angleSnap;
      ripple = cfg.dpi.ripple;
    };
    polling = cfg.pollingRate;
    light = {
      inherit (cfg.lighting) mode color brightness speed;
      sleep = cfg.power.sleep;
      deep_sleep = cfg.power.deepSleep;
      debounce = cfg.power.debounce;
    };
    inherit buttons;
  };

  apply = pkgs.writeShellApplication {
    name = "shark-apply";
    runtimeInputs = [python pkgs.util-linux];
    text = ''
      export PYTHONPATH=${pythonSite}
      exec flock -w 10 "''${XDG_RUNTIME_DIR:-/tmp}/sharkx11-apply.lock" python3 ${../scripts/apply.py} "$@"
    '';
  };
in {
  options.programs.sharkx11 = {
    enable = lib.mkEnableOption "the ATTACK SHARK X11 mouse configurator";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ../package.nix {};
      defaultText = lib.literalExpression "pkgs.callPackage ./package.nix {}";
      description = "The package providing x11ctl and x11gui.";
    };

    dpi = {
      stages = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule {
          options = {
            dpi = lib.mkOption {
              type = lib.types.ints.between 50 22000;
              description = "DPI of the stage.";
            };
            color = lib.mkOption {
              type = lib.types.strMatching "#[0-9a-fA-F]{6}";
              description = "Colour of the stage, shown only in the DPI-lighting modes.";
            };
          };
        });
        default = [
          {
            dpi = 800;
            color = "#ff0000";
          }
          {
            dpi = 1600;
            color = "#00ff00";
          }
          {
            dpi = 2400;
            color = "#0000ff";
          }
          {
            dpi = 3200;
            color = "#ffff00";
          }
          {
            dpi = 5000;
            color = "#00ffff";
          }
          {
            dpi = 22000;
            color = "#ff00ff";
          }
        ];
        description = "Enabled DPI stages, in order (1 to 8); stages past the last entry are disabled.";
      };
      activeStage = lib.mkOption {
        type = lib.types.ints.between 1 8;
        default = 2;
        description = "The stage selected when the mouse powers on.";
      };
      angleSnap = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Straighten small movements.";
      };
      ripple = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Ripple effect of the DPI changes.";
      };
    };

    pollingRate = lib.mkOption {
      type = lib.types.enum [125 250 500 1000];
      default = 1000;
      description = "USB polling rate in Hz.";
    };

    lighting = {
      mode = lib.mkOption {
        type = lib.types.enum ["off" "static" "breathing" "neon" "color_breathing" "static_dpi" "breathing_dpi"];
        default = "off";
        description = "Lighting animation.";
      };
      color = lib.mkOption {
        type = lib.types.strMatching "#[0-9a-fA-F]{6}";
        default = "#00ff00";
        description = "Lighting colour.";
      };
      brightness = lib.mkOption {
        type = lib.types.ints.between 1 8;
        default = 8;
        description = "Brightness; the firmware only applies it to the static modes.";
      };
      speed = lib.mkOption {
        type = lib.types.ints.between 1 5;
        default = 3;
        description = "Animation speed.";
      };
    };

    power = {
      sleep = lib.mkOption {
        type = lib.types.ints.between 1 60;
        default = 1;
        description = "Minutes of inactivity before the mouse sleeps.";
      };
      deepSleep = lib.mkOption {
        type = lib.types.ints.between 1 60;
        default = 10;
        description = "Minutes of inactivity before deep sleep.";
      };
      debounce = lib.mkOption {
        type = lib.types.ints.between 2 25;
        default = 4;
        description = "Button debounce time in milliseconds.";
      };
    };

    buttons = lib.genAttrs ["left" "right" "middle" "forward" "back"] (name:
      lib.mkOption {
        type = lib.types.str;
        default = name;
        example = "key:ctrl+shift+t";
        description = "Action of the ${name} button: a name from `x11ctl actions` or `key:<modifiers+key>`.";
      });
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.length cfg.dpi.stages >= 1 && lib.length cfg.dpi.stages <= 8;
        message = "programs.sharkx11.dpi.stages must have 1 to 8 entries.";
      }
      {
        assertion = cfg.dpi.activeStage <= lib.length cfg.dpi.stages;
        message = "programs.sharkx11.dpi.activeStage must point at one of the declared stages.";
      }
      {
        assertion = lib.all (s: (s.dpi <= 10000 && lib.mod s.dpi 50 == 0) || (s.dpi >= 10100 && lib.mod s.dpi 100 == 0)) cfg.dpi.stages;
        message = "programs.sharkx11.dpi.stages[].dpi must be 50..10000 in steps of 50 or 10100..22000 in steps of 100.";
      }
    ];

    home.packages = [shark];

    xdg.configFile."sharkx11/buttons.json".source = buttonsFile;

    xdg.dataFile."applications/attack-shark.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=ATTACK SHARK X11
      Comment=DPI stages, polling, buttons, lighting and battery
      Exec=${shark}/bin/x11gui
      Icon=input-mouse
      Categories=Utility;Settings;
    '';

    # Settings live in the mouse's firmware, so the module pushes them. The udev rules in
    # modules/nixos.nix ask for this unit whenever the mouse appears; WantedBy covers login.
    systemd.user.services.sharkx11-apply = {
      Unit = {
        Description = "Apply the declared ATTACK SHARK X11 settings";
        StartLimitIntervalSec = 30;
        StartLimitBurst = 5;
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${apply}/bin/shark-apply ${settingsFile}";
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = ["default.target"];
    };
  };
}
