obj-m := amg88xx.o

SRC := $(shell pwd)
KERNEL_SRC := /lib/modules/$(shell uname -r)/build

all:
	$(MAKE) -C $(KERNEL_SRC) M=$(SRC) modules

install:
	$(MAKE) -C $(KERNEL_SRC) M=$(SRC) modules_install

clean:
	$(MAKE) -C $(KERNEL_SRC) M=$(SRC) clean
	
.DEFAULT:
	$(MAKE) -C $(KERNEL_SRC) M=$(SRC) $@
