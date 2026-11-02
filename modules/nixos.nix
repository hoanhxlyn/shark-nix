{pkgs, ...}: {
  # Config interface of the 2.4G dongle (1d57:fa60) and of the wired mouse (1d57:2125):
  # without the uaccess tag the GUI cannot open /dev/hidraw*. 70-* so the tag is set
  # before systemd's 73-seat-late.rules hands the ACL out (99-local.rules is too late).
  services.udev.packages = [
    (pkgs.writeTextFile {
      name = "attack-shark-udev-rules";
      destination = "/etc/udev/rules.d/70-attack-shark.rules";
      text = ''
        SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1d57", TAG+="uaccess"
      '';
    })
  ];
}
