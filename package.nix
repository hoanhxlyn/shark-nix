# ATTACK SHARK mouse configurator (Tk GUI + CLI) from source; not in nixpkgs.
{
  lib,
  python3Packages,
  fetchzip,
}:
python3Packages.buildPythonApplication rec {
  pname = "sharkx11";
  version = "0.1.0b4";

  src = fetchzip {
    url = "https://github.com/MiguelSanzBr/attackshark-x11-linux/archive/6622b800a0a0346d950c7b751d7a53cc82fff26b.tar.gz";
    hash = "sha256-Wp9GRXY006KJp8J3mUKr47Dj35xXZGrBEEkMwk2IKKc=";
  };

  pyproject = true;
  build-system = [python3Packages.setuptools];
  propagatedBuildInputs = [python3Packages.tkinter];
  doCheck = false; # its test suite is not worth wiring up for a desktop tool

  meta = {
    description = "Attack Shark X11 mouse configurator: DPI, polling, buttons, lighting, battery";
    homepage = "https://github.com/MiguelSanzBr/attackshark-x11-linux";
    license = lib.licenses.mit;
    mainProgram = "x11gui";
  };
}
