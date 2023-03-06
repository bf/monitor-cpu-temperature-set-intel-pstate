#!/bin/bash

# This script monitors CPU temperature and decreases max. CPU speed to cool down
# Only works with Intel CPUs and intel_pstate kernel module. 
#
# Once CPU is cooled down, the max. CPU speed will be increased. 
# This allows dynamic reaction to load.
# 
# To be combined with `thinkfan`
#
# Tested with i7-3720QM on arch linux
#
# Author:  Benjamin Flesch
# License: MIT
# Date:    2023

# write pid to file
echo $$ > /run/monitor-cpu-temperature-set-intel-pstate.pid

# Use `$echoLog` everywhere you print verbose logging messages to console
# By default, it is disabled and will be enabled with the `-v` or `--verbose` flags
# see https://stackoverflow.com/a/25984249
declare echoLog='silentEcho'
function silentEcho() {
    :
}

# Somewhere else in your script's setup, do something like this
while [[ $# > 0 ]]; do
    case "$1" in
        -v|--verbose) echoLog='echo'; ;;
    esac
    shift;
done

# monitor cpu temperature and if it is higher than certain threshold reduce max CPU % using intel_pstate
MAX_CPU_TEMPERATURE_CELSIUS=90;

# maxium tolerance so we don't change values too often
MAX_TOLERANCE_CELSIUS=2;

# how much cpu max perf percentage should be changed with every step
PERCENTAGE_CHANGE=1;

# multiply by 1000 to compare with sensor values
THRESHOLD_TEMP=$(( $MAX_CPU_TEMPERATURE_CELSIUS * 1000 ));
TOLERANCE_TEMP=$(( $MAX_TOLERANCE_CELSIUS * 1000 ))

while true; do
	# read computer temp
	CURRENT_TEMP=$(grep -hEo '[0-9]+' /sys/devices/platform/coretemp.*/hwmon/hwmon*/temp*_input | sort -rn | head -n 1)
	$echoLog CURRENT_TEMP: $CURRENT_TEMP;

	if [[ -z "$CURRENT_TEMP" ]]; then
		echo "Error: could not read current temp";
		exit 1;
	fi;

	# read current intel pstate max % setting
	PATH_PSTATE_MAX_PERF_PCT="/sys/devices/system/cpu/intel_pstate/max_perf_pct";
	CURRENT_MAX_PERF_PCT=$(cat $PATH_PSTATE_MAX_PERF_PCT);
	$echoLog "CURRENT_MAX_PERF_PCT: $CURRENT_MAX_PERF_PCT";

	if [[ -z "CURRENT_MAX_PERF_PCT" ]]; then
		echo "Error: could not read value from $PATH_PSTATE_MAX_PERF_PCT";
		exit 2;
	fi;

	# read current intel pstate min % 
	PATH_PSTATE_MIN_PERF_PCT="/sys/devices/system/cpu/intel_pstate/min_perf_pct";
	CURRENT_MIN_PERF_PCT=$(cat $PATH_PSTATE_MIN_PERF_PCT);
	# echo "CURRENT_MIN_PERF_PCT: $CURRENT_MIN_PERF_PCT";
	if [[ -z "CURRENT_MIN_PERF_PCT" ]]; then
		echo "Error: could not read value from $PATH_PSTATE_MIN_PERF_PCT";
		exit 3;
	fi;

	# check if threshold temp is reached
	# echo "THRESHOLD_TEMP: $THRESHOLD_TEMP";

	if [[ "$CURRENT_TEMP" -lt "$THRESHOLD_TEMP" ]] && [[ "$CURRENT_MAX_PERF_PCT" -eq "100" ]]; then
		$echoLog "nothing to do";
	else
		TEMP_DIFFERENCE=$(( "$CURRENT_TEMP" - "$THRESHOLD_TEMP" ));
		$echoLog "TEMP_DIFFERENCE: $TEMP_DIFFERENCE";

		if [[ "$TEMP_DIFFERENCE" -le "$TOLERANCE_TEMP" ]]; then
			$echoLog "temp is not higher than $THRESHOLD_TEMP";
			
			# increment intel pstate until max is reached
			CHANGE_BY_PERCENTAGE_POINTS=$PERCENTAGE_CHANGE;
		elif [[ "$TEMP_DIFFERENCE" -ge "$TOLERANCE_TEMP" ]]; then
			$echoLog "temp is higher than $THRESHOLD_TEMP, decrease CPU power";

			# decrement intel pstate until max is reached
			CHANGE_BY_PERCENTAGE_POINTS=-$PERCENTAGE_CHANGE;
		else
			$echoLog "temp within tolerance of $MAX_TOLERANCE_CELSIUS degrees celsius";

			# dont change
			CHANGE_BY_PERCENTAGE_POINTS=0;
		fi;

		# calculate next value
		NEXT_MAX_PERF_PCT=$(( "$CURRENT_MAX_PERF_PCT" + "$CHANGE_BY_PERCENTAGE_POINTS" ))

		# check if value changed at all
		if [[ "$NEXT_MAX_PERF_PCT" -eq "$CURRENT_MAX_PERF_PCT" ]]; then
			$echoLog "NEXT_MAX_PERF_PCT $NEXT_MAX_PERF_PCT is CURRENT_MAX_PERF_PCT $CURRENT_MAX_PERF_PCT, nothing to do.";
		else

			$echoLog "NEXT_MAX_PERF_PCT: $NEXT_MAX_PERF_PCT";

			if [[ "$NEXT_MAX_PERF_PCT" -le "$CURRENT_MIN_PERF_PCT" ]]; then
				$echoLog "NEXT_MAX_PERF_PCT $NEXT_MAX_PERF_PCT is lower than minimum CURRENT_MIN_PERF_PCT $CURRENT_MIN_PERF_PCT, limiting to $CURRENT_MIN_PERF_PCT";
				NEXT_MAX_PERF_PCT=$CURRENT_MIN_PERF_PCT;
				$echoLog "new NEXT_MAX_PERF_PCT: $NEXT_MAX_PERF_PCT";
			fi;

			if [[ "$NEXT_MAX_PERF_PCT" -ge "100" ]]; then
				$echoLog "NEXT_MAX_PERF_PCT $NEXT_MAX_PERF_PCT is larger than 100, limiting to 100";
				NEXT_MAX_PERF_PCT=100;
				$echoLog "new NEXT_MAX_PERF_PCT: $NEXT_MAX_PERF_PCT";
			fi;

			$echoLog "writing NEXT_MAX_PERF_PCT $NEXT_MAX_PERF_PCT to $PATH_PSTATE_MAX_PERF_PCT";
			echo -n $NEXT_MAX_PERF_PCT > $PATH_PSTATE_MAX_PERF_PCT;
		fi;
	fi;

	SLEEP_SECONDS=1;
	$echoLog "Sleeping for $SLEEP_SECONDS seconds ...";
	sleep $SLEEP_SECONDS;
done;
