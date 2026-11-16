# Gera qnoc-x1e80100.ko (mesmo nome do módulo do Ubuntu) a partir de qnoc-83gh.c
obj-m := qnoc-x1e80100.o
qnoc-x1e80100-y := qnoc-83gh.o

KDIR ?= /root/build/hdr/usr/src/linux-headers-7.3.0-15-qcom-x1e

all:
	$(MAKE) -C $(KDIR) M=$(CURDIR) modules

clean:
	$(MAKE) -C $(KDIR) M=$(CURDIR) clean
