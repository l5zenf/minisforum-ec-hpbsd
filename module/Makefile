# SPDX-License-Identifier: GPL-2.0
# Out-of-tree build for local testing; DKMS uses dkms.conf instead.
KDIR ?= /lib/modules/$(shell uname -r)/build

# CachyOS kernels are built with clang; out-of-tree modules must match.
CC ?= clang
LD ?= ld.lld

all:
	$(MAKE) -C $(KDIR) M=$(CURDIR) CC=$(CC) LD=$(LD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(CURDIR) clean

.PHONY: all clean
