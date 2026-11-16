#!/bin/bash
# Testa em que combinação de overlays o gpio-reserved-ranges do tlmm volta ao valor do Slim 5x.
B=/root/build; T=/soc@0/pinctrl@f100000
t() { fdtoverlay -i $B/slim5x-as-2in1.dtb -o /tmp/t.dtb $(for o in "$@"; do echo $B/83gh-$o.dtbo; done) \
      && echo "$*: $(fdtget /tmp/t.dtb $T gpio-reserved-ranges)"; }
t camera
t touchscreen camera
t camera touchscreen
t input touchscreen firmware camera
