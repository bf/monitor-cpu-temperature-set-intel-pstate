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
