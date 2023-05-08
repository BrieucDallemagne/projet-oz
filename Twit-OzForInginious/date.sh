#!/bin/bash

# put current date as yyyy-mm-dd in $date
# -1 -> explicit current date, bash >=4.3 defaults to current time if not provided
# -2 -> start time for shell
#printf -v date '%(%Y-%m-%d)T\n' -1 

# put current date as yyyy-mm-dd HH:MM:SS in $date
printf -v date '%(%Y-%m-%d %H:%M:%S)T\n' -2 

# to print directly remove -v flag, as such:
printf '%(%Y-%m-%d)T\n' -1
printf '%(%Y-%m-%d_%H:%M:%S)T\n' -1
Test=$(date +%s)

echo $Test


