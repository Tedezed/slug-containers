#!/bin/bash

id_node=$1
host_name=$2
datetime=$(date +"(%m-%d-%y %T)")

echo "[FAILBACK] $datetime $id_node $host_name" >> /tmp/failback.log