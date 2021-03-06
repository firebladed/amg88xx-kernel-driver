# AMG88xx-series sensor device driver
This is a simple Linux device driver for the Panasonic amg88xx-series thermal cameras.
**This project is still in a very early stage!**

The amg88xx sensors use i2c-interface and a single interrupt line for communication.
This driver exposes the i2c registers to userspace via sysfs. Some extra features are
also exposed, please take a look at the [sysfs interface](#sysfs-interface) chapter for more info.

## TODO
- [X] add support for the device interrupt
  - [X] sysfs entry for the interrupt
  - [X] interrupt handling in kernel
  - [X] notifying userspace through the sysfs
- [ ] complete the sysfs interface
- [X] finish the devicetree overlay
- [ ] add support for an "easier" interface (_/class/iio_ maybe?)
- [ ] add Video4Linux support
- [ ] write an example userspace application


## How to use
First clone this reposity:

`git clone https://github.com/firebladed/amg88xx-kernel-driver.git`

## Compile Devicetree

In order for this driver to function properly the devicetree needs to have an entry
for the amg88xx sensor. This repo provides a sample devicetree overlay for Raspberry.

Compile the devicetree overlay with `dtc`:

`dtc -W no-unit_address_vs_reg -O dtb -I dts -o amg88xx.dtbo amg88xx-overlay.dts`

And load it with `dtoverlay`:

`sudo dtoverlay amg88xx.dtbo`

## Build and install using Dkms

install dkms if missing
`sudo apt install dkms`

Build using dkms
`cd amg88xx-kernel-driver`
`sudo dkms build ./`

Install using dkms
`sudo dkms install -m amg88xx-kernel-driver -v 0.1`


## Build and install Manually
Then use the supplied `Makefile` to build the driver (make sure that you have the proper
kernel headers installed):

`cd amg88xx-kernel-driver && make`

Finally load the module:

`sudo insmod amg88xx.ko`

## Check Module loaded

The sysfs entries are found in the `/sys/bus/i2c/device/<device_name>/` directory. You can find
the right `device_name` by running the following command:

`cd /sys/bus/i2c/devices/ && ls * | grep amg88xx */name`

Before the device can be used it must be set to _normal_ or one of the _stand-by_ modes:

`sudo sh -c "echo <mode> > device_mode"`

`mode` can be any on of the following:
 * `normal` Normal operation, refresh rate chosen by the _FPSC_ register
 * `sleep` Sleep mode, all register read as 0x0
 * `standby_60` Stand-by mode with wake-up every 60 s to refresh the sensor and the irq line
 * `standby_10` Stand-by mode with wake-up every 10 s to refresh the sensor and the irq line

## Devicetree overlay
The amg88xx-overlay.dts contains an example devicetree overlay that can be used with Raspberry
Pi. The devicetree needs the following nodes:
 * node for the device pinctrl
   * check the documentation for the gpio controller in your system for implementation
   * this node should specify a single gpio as an input and use a pull up (if possible)
 * node for the i2c device
   * `reg` has to be 0x68 or 0x69 (depending on the hw configuration)
   * `compatible = "panasonic,amg88xx"`
   * `interrupt-gpio` to tie gpio line for reading the interrupt state from the hw
   * `interrupts` should be configured on the same gpio pin as the interrupt-gpio
   * `interrupt-parent` should be set to point the interrupt controller of this node (propably
     a gpio controller node)
   * a link to the device pinctrl should be provided via `pinctrl-0`and `pinctrl-names`

## sysfs interface
**The sysfs interface is not fully implemented!**
This driver exposes the following sysfs files:
 * `device_mode` i2c register: _PCTL_
   * reading this file returns the device mode:
     * `normal` Normal operation, refresh rate chosen by the _FPSC_ register
     * `sleep` Sleep mode, all register read as 0x0
     * `standby_60` Stand-by mode with wake-up every 60 s to refresh sensor and irq line
     * `standby_10` Stand-by mode with wake-up every 10 s to refresh sensor and irq line
   * writing a correct device mode to this file sets the device mode
 * `reset` i2c register: _RST_
   * following values can be writin to this file:
     * `full` device is reseted to the initial state
     * `partial` only the status register, interrupt flag and interrupt map is reseted
 * `framerate` i2c register: _FPSC_
   * reading this file returns the current framerate or 0 if the device is in sleep mode
   * writing a valid value (`1` or `10`) to this file sets the framerate
 * `interrupt_state` i2c register: _INTC_ bit 0
   * reading this file returns the value of interrupt enabled bit:
     * `enabled` interrupt line is in use
     * `disabled` interrupt line is not in use
   * writing this file changes the interrupt enabled bit
 * `interrupt_mode` i2c register: _INTC_ bit 1
   * reading this file returns the value interrupt mode bit:
     * `absolute`
     * `differential` TODO what is the difference between the two
   * writing this file changes the interrupt mode bit
 * `interrupt_levels` i2c registers: _INTHL_ to _IHYSH_
   * reading this file returns the interrupt upper and lower limits and the
     hysteresis in the following format: `upper,lower,hysteresis`. All values are signed integers
   * writing this file sets the interrupt limits and hysteresis. All three values must be writen
     at the same time
 * `interrupt` this file maps the interrupt gpio to userspace:
   * `active` the interrupt gppio pin is low, i.e. there is an active interrupt
   * `not_active` the interrupt gpio pin is high, i.e. there isn't an active interrupt
   * This file will recieve a notify from the kernel when a new interrupt is recieved. So
     the file can be poll()'ed by userspace programs. TODO add an example.
 * `interrupt_map` i2c register: _INT0_ to _INT7_
   * reading this file returns a 8x8 map showing which pixels are generating interrupts
 * `thermistor` i2c registers: _TTHL_ and _TTHH_.
   * reading this file returns the thermistor output in signed integer format
 * `sensor` i2c registers: _T01L_ to _0xFF_
   * reading this file returns the 8x8 array containing the sensor values in signed integer format
