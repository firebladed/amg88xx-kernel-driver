# AMG88xx-series sensor device driver
This is a simple Linux device driver for the Panasonic amg88xx-series thermal cameras.
**This project is still in a very early stage!**

The amg88xx sensors use the i2c-interface and a single interrupt line for communication.
This driver exposes the i2c registers to userspace via sysfs. Some extra features are
also exposed, please take a look at the [sysfs interface](#sysfs-interface) chapter for more info.

## TODO
- [X] add support for the device interrupt
- [ ] complete the sysfs interface
- [ ] finish the device tree overlay

## How-to use
First clone this reposity:

```git clone https://github.com/vuorioi/amg88xx-kernel-driver.git```

Then use the supplied `Makefile` to build the driver (make sure that you have the proper
kernel headers installed):

```cd amg88xx-kernel-driver && make```

In order for this driver to function properly the device tree needs to have an entry
for the amg88xx sensor. This repo provides a sample device tree overlay for Raspberry.

Compile the device tree overlay with `dtc`:

```dtc -W no-unit_address_vs_reg -O dtb -I dts -o amg88xx.dtbo amg88xx-overlay.dts```

And load it with `dtoverlay`:

```sudo dtoverlay amg88xx.dtbo```

Finally load the module:

```sudo insmod amg88xx.ko```

The sysfs entries are found in the `/sys/bus/i2c/device/<device_name>/` directory. You can find
the right `device_name` by running the following command:

```cd /sys/bus/i2c/devices/ && ls * | grep amg88xx */name```

Before the device can be used it must be set to _normal_ or one of the _stand-by_ modes:

```sudo sh -c "echo <mode> > device_mode"```

`mode` can be any on of the following:
 * `0x0` Normal mode
 * `0x10` Sleep mode
 * `0x20` Stand-by mode (60 s)
 * `0x21` Stand-by mode (10 s)

## sysfs interface
**The sysfs interface is not fully implemented!**
This driver exposes the following sysfs files:
 * `device_mode` i2c register: _PCTL_
   * reading this file returns the device mode in hex encoding
   * writing a correct hex encoded value to this file sets the device mode
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
     hysteresis in the following format: `upper,lower,hysteresis`
   * writing this file sets the interrupt limits and hysteresis. All three values must be writen
 * `interrupt` this file maps the interrupt line to userspace:
   * `active` there is an interrupt condition
   * `not_active` there is no interrupt condition
     at the same time
 * `thermistor` i2c registers: _TTHL_ and _TTHH_.
   * reading this file returns the thermistor output in hex encoding
 * `sensor` i2c registers: _T01L_ to _0xFF_
   * reading this file returns the 8x8 array containing the sensor values in hex encoding
