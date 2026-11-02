# Battery from the mouse's own 2 s heartbeat (input report 0x03): no feature report is
# sent, so reading it never stalls pointer motion the way a full settings read does.
import sys

from sharkx11 import device

battery = device.Device().wait_battery(4.0)
if not battery:
    sys.exit(1)
print(battery[1])
