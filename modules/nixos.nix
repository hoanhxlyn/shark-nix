{pkgs, ...}: {
  # The mouse's interfaces: 2.4G receiver (1d57:fa60), X11 on cable (1d57:fa55) and X11SE on
  # cable (1d57:2125). Product-scoped so other 1d57 devices keep their ACLs. Without the
  # uaccess tag the GUI cannot open /dev/hidraw*; 70-* so the tag is set before systemd's
  # 73-seat-late.rules hands the ACL out (99-local.rules is too late). The systemd tag starts
  # the user unit that applies the declared settings whenever the mouse appears.
  services.udev.packages = [
    (pkgs.writeTextFile {
      name = "attack-shark-udev-rules";
      destination = "/etc/udev/rules.d/70-attack-shark.rules";
      text = ''
        SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1d57", ATTRS{idProduct}=="fa60", TAG+="uaccess", TAG+="systemd", ENV{SYSTEMD_USER_WANTS}+="sharkx11-apply.service"
        SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1d57", ATTRS{idProduct}=="fa55", TAG+="uaccess", TAG+="systemd", ENV{SYSTEMD_USER_WANTS}+="sharkx11-apply.service"
        SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1d57", ATTRS{idProduct}=="2125", TAG+="uaccess", TAG+="systemd", ENV{SYSTEMD_USER_WANTS}+="sharkx11-apply.service"
      '';
    })
  ];
}
