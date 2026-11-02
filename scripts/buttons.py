"""Write the app's 18-slot buttons.json from a {left, right, middle, forward, back} map.

Run at build time with the package importable, so the action names and "key:..." shortcuts are
validated by sharkx11 itself instead of a copy of its tables.
"""

import json
import sys

from sharkx11 import config

buttons = json.loads(sys.argv[1])
mapping = list(config.DEFAULT_MAP)
for name, slot in config.BUTTONS.items():
    text = buttons[name]
    mapping[slot] = config.parse_shortcut(text[4:]) if text.startswith("key:") else text
config.encode_buttons(mapping)  # raises on an unknown action or shortcut
json.dump(mapping, sys.stdout, indent=2)
