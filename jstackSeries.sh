#!/bin/bash
# Adaptation of script from eclipse.org
# http://wiki.eclipse.org/How_to_report_a_deadlock#jstackSeries_--_jstack_sampling_in_fixed_time_intervals_.28tested_on_Linux.29

if [ $# -eq 0 ]; then
    echo >&2 "Usage: jstackSeries <pid> [ <count> [ <delay> ] ]"
    echo >&2 "    Defaults: count = 10, delay = 1 (seconds)"
    exit 1
fi

pid=$1          # required
count=${2:-10}  # defaults to 10 times
delay=${3:-1} # defaults to 1 second

while [ $count -gt 0 ]
do
    jstack $pid >jstack.$pid.$(date +%s.%N)
    top -H -b -n1 -p $pid >top.$pid.$(date +%s.%N)
    sleep $delay
    let count--
    echo -n "."
done
