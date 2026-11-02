{
  description = "Nix flake for the ATTACK SHARK X11 gaming mouse";

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];

      flake = {
        nixosModules.default = ./modules/nixos.nix;
        homeManagerModules.default = ./modules/home.nix;
      };

      perSystem = {pkgs, ...}: let
        shark = pkgs.callPackage ./package.nix {};
      in {
        packages.default = shark;
        # Battery only, via the mouse's 2 s heartbeat: `x11ctl info` also fetches every
        # setting, and that feature-report handshake stalls pointer motion for ~4 s.
        packages.shark-battery = pkgs.writeShellApplication {
          name = "shark-battery";
          runtimeInputs = [pkgs.python3];
          text = ''
            export PYTHONPATH=${shark}/lib/python${pkgs.lib.versions.majorMinor pkgs.python3.version}/site-packages
            python3 ${./scripts/battery.py}
          '';
        };
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [alejandra statix deadnix];
        };
      };
    };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };
}
