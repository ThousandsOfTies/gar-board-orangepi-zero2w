#!/bin/sh
# Armbian USB0: Windows RNDIS networking and the existing ttyGS0 console.
set -eu
G=/sys/kernel/config/usb_gadget/gar_usb_link
case "${1:-}" in
  start)
    test "$(id -u)" = 0
    modprobe libcomposite
    mountpoint -q /sys/kernel/config || mount -t configfs none /sys/kernel/config
    if test -d "$G"; then
      test -n "$(cat "$G/UDC")" && exit 0
      echo 'An incomplete gar_usb_link gadget exists; inspect it before starting.' >&2
      exit 1
    fi
    test "$(ls -1 /sys/class/udc | wc -l)" = 1
    UDC=$(ls -1 /sys/class/udc)
    # The caller stops the legacy serial gadget before switching configurations.
    if test -d /sys/module/g_serial; then
      echo 'Stop the legacy g_serial gadget before starting the composite link.' >&2
      exit 1
    fi
    identity=$(cat /etc/machine-id)
    suffix=$(printf '%s' "$identity" | sha256sum | cut -c1-10 | sed 's/../&:/g;s/:$//')
    mkdir "$G"
    printf '0x1d6b' > "$G/idVendor"
    printf '0x0104' > "$G/idProduct"
    printf '0x0200' > "$G/bcdUSB"
    printf '0x0100' > "$G/bcdDevice"
    printf '0xEF' > "$G/bDeviceClass"
    printf '0x02' > "$G/bDeviceSubClass"
    printf '0x01' > "$G/bDeviceProtocol"
    mkdir "$G/strings/0x409"
    printf '%s' "$identity" > "$G/strings/0x409/serialnumber"
    printf 'Orange Pi' > "$G/strings/0x409/manufacturer"
    printf 'Orange Pi USB network and console' > "$G/strings/0x409/product"
    mkdir "$G/configs/c.1" "$G/configs/c.1/strings/0x409"
    printf 'RNDIS and ACM' > "$G/configs/c.1/strings/0x409/configuration"
    printf '250' > "$G/configs/c.1/MaxPower"
    mkdir "$G/functions/rndis.usb0"
    printf '02:%s' "$suffix" > "$G/functions/rndis.usb0/host_addr"
    printf '06:%s' "$suffix" > "$G/functions/rndis.usb0/dev_addr"
    printf 'RNDIS' > "$G/functions/rndis.usb0/os_desc/interface.rndis/compatible_id"
    printf '5162001' > "$G/functions/rndis.usb0/os_desc/interface.rndis/sub_compatible_id"
    printf '1' > "$G/os_desc/use"
    printf '0xcd' > "$G/os_desc/b_vendor_code"
    printf 'MSFT100' > "$G/os_desc/qw_sign"
    ln -s "$G/configs/c.1" "$G/os_desc/c.1"
    # RNDIS must be the first interfaces for automatic Windows driver binding.
    ln -s "$G/functions/rndis.usb0" "$G/configs/c.1/rndis.usb0"
    mkdir "$G/functions/acm.usb0"
    ln -s "$G/functions/acm.usb0" "$G/configs/c.1/acm.usb0"
    printf '%s' "$UDC" > "$G/UDC"
    ;;
  stop)
    test "$(id -u)" = 0
    test -d "$G" || exit 0
    if test -n "$(cat "$G/UDC")"; then printf '\n' > "$G/UDC"; fi
    rm -f "$G/configs/c.1/acm.usb0" "$G/configs/c.1/rndis.usb0" "$G/os_desc/c.1"
    for directory in "$G/configs/c.1/strings/0x409" "$G/configs/c.1" \
      "$G/functions/acm.usb0" "$G/functions/rndis.usb0" "$G/strings/0x409"; do
      if test -d "$directory"; then rmdir "$directory"; fi
    done
    rmdir "$G"
    ;;
  *) echo 'Usage: usb-link.sh start|stop' >&2; exit 2 ;;
esac
