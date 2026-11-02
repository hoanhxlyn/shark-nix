"""Write the declarative settings file to the mouse in one connection.

Only the button map and the DPI/lighting reports are cached locally; the rest lives in the
firmware, so the declared values have to be pushed. Reports are read first and only the
declared fields are changed, exactly like ``x11ctl`` does.
"""

import json
import sys

from sharkx11 import config, device, protocol as p


def action(text):
    return config.parse_shortcut(text[4:]) if text.startswith("key:") else text


def main(path):
    with open(path, encoding="utf-8") as f:
        cfg = json.load(f)

    dev = device.Device()
    try:
        dpi = config.decode_dpi(dev.read(p.DPI))
        for i, stage in enumerate(dpi["stages"]):
            stage["on"] = i < len(cfg["dpi"]["stages"])
            if stage["on"]:
                stage["dpi"] = cfg["dpi"]["stages"][i]["dpi"]
                stage["color"] = cfg["dpi"]["stages"][i]["color"]
        dpi["active"] = cfg["dpi"]["active"]
        dpi["angle_snap"] = cfg["dpi"]["angle_snap"]
        dpi["ripple"] = cfg["dpi"]["ripple"]

        light = config.decode_light(dev.read(p.LIGHT))
        light.update(cfg["light"])

        dev.write(config.encode_dpi(dpi))
        dev.write(config.encode_light(light))
        dev.write(config.encode_polling(cfg["polling"]))
        dev.write(config.encode_buttons([action(a) for a in cfg["buttons"]]))
    finally:
        dev.close()


if __name__ == "__main__":
    main(sys.argv[1])
