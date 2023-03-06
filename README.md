# monitor-cpu-temperature-set-intel-pstate

Monitor CPU temperature and change `/sys/devices/system/cpu/intel_pstate/max_perf_pct` to assist cooling down the CPU.

This script monitors CPU temperature and decreases maximum CPU speed to cool down (this supports cooling when the fans are not strong enough). Relies on intel_pstate kernel module and therefore only works with Intel CPUs. 

Once CPU is cooled down, the max. CPU speed will be increased again. This allows dynamic reaction to load, such as viewing videos.

To be combined with `thinkfan` which controls the fan speed and `tlp` which controlls the same `max_perf_pct` and battery saving setting. Tested with Thinkpad T430 i7-3720QM on arch linux.

# Installation

- Open root console
- Copy `monitor-cpu-temperature-set-intel-pstate.service` to `/etc/systemd/system/`
- Copy `monitor-temp.sh` to `/usr/bin/`
- Run `chmod +x /usr/bin/monitor-temp.sh` so script can be executed
- Run `systemctl daemon-reload` to reload systemd
- Run `systemctl enable monitor-cpu-temperature-set-intel-pstate.service` to activate service
- Run `systemctl start monitor-cpu-temperature-set-intel-pstate.service` to start

# Logging

If you want to see it in action, run some CPU-intensive tasks (e.g. open multiple twitch streams at the same time).
Then you can monitor `max_perf_pct` and your CPU temperature like this:

```bash
watch -n 1 "cat /sys/devices/system/cpu/intel_pstate/max_perf_pct; sensors"
```

# Thinkfan configuration

We use Thinkfan for changing CPU cooling fan speed on Thinkpad 430 with this config `/etc/thinkfan.conf`

```conf
# Thinkfan config for Thinkpad T430 with i7-3720QM
tp_fan /proc/acpi/ibm/fan
hwmon /sys/devices/platform/coretemp.0/hwmon/hwmon4/temp3_input
hwmon /sys/devices/platform/coretemp.0/hwmon/hwmon4/temp4_input
hwmon /sys/devices/platform/coretemp.0/hwmon/hwmon4/temp5_input
hwmon /sys/devices/platform/coretemp.0/hwmon/hwmon4/temp1_input
hwmon /sys/devices/platform/coretemp.0/hwmon/hwmon4/temp2_input


(0,	0,	55)
(1,	48,	60)
(2,	50,	61)
(3,	52,	63)
(4,	56,	65)
(5,	59,	66)
(7,	63,     79)
("level full-speed", 75, 32767) # 5000 rpm
```