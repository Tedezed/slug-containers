#!/bin/bash

# Copyright 2015 Crunchy Data Solutions, Inc.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# clean up leftovers from previous runs of pgpool
rm -rf /tmp/pgpool.pid
rm -rf /tmp/.s.*

BINDIR=/opt/cpm/bin
CONFDIR=/opt/cpm/conf/pgpool
CONFIGS=/tmp

env

function trap_sigterm() {
	echo "doing trap logic..."
	kill -SIGINT $PGPOOL_PID
}

trap 'trap_sigterm' SIGINT SIGTERM


# seed with defaults included in the container image, this is the
# case when /pgconf is not specified
cp $CONFDIR/* /tmp

# populate template with env vars
sed -i "s/PG_PRIMARY_SERVICE_NAME/$PG_PRIMARY_SERVICE_NAME/g" $CONFIGS/pgpool.conf
sed -i "s/PG_REPLICA_SERVICE_NAME/$PG_REPLICA_SERVICE_NAME/g" $CONFIGS/pgpool.conf
sed -i "s/PG_USERNAME/$PG_USERNAME/g" $CONFIGS/pgpool.conf
sed -i "s/PG_PASSWORD/$PG_PASSWORD/g" $CONFIGS/pgpool.conf

# Personal configuration
sed -i "s/PG_NUM_INIT_CHILDREN/$PG_NUM_INIT_CHILDREN/g" $CONFIGS/pgpool.conf
sed -i "s/PG_MAX_POOL/$PG_MAX_POOL/g" $CONFIGS/pgpool.conf
sed -i "s/PG_MULTIPLER_BACK/$PG_MULTIPLER_BACK/g" $CONFIGS/pgpool.conf
sed -i "s/PG_CHILD_LIFE_TIME/$PG_CHILD_LIFE_TIME/g" $CONFIGS/pgpool.conf
sed -i "s/PG_CLIENT_IDLE_LIMIT/$PG_CLIENT_IDLE_LIMIT/g" $CONFIGS/pgpool.conf
sed -i "s/PG_MAX_CONNECTIONS/$PG_MAX_CONNECTIONS/g" $CONFIGS/pgpool.conf
sed -i "s/PG_SUPERUSER_RESERVED_CONNECTIONS/$PG_SUPERUSER_RESERVED_CONNECTIONS/g" $CONFIGS/pgpool.conf

#PCP
sed -i "s/PCP_PORT/$PCP_PORT/g" $CONFIGS/pgpool.conf

# Debug and log
sed -i "s/PG_DEBUG/$PG_DEBUG/g" $CONFIGS/pgpool.conf
sed -i "s/PG_LOG/$PG_LOG/g" $CONFIGS/pgpool.conf

if [ $DOCKER_DEBUG == "on" ]; then
	sleep 999999999
fi

# Populate pool_passwd file
pg_md5 --md5auth --username=$PG_USERNAME --config=$CONFIGS/pgpool.conf $PG_PASSWORD

# PCP without password
echo "$PG_USERNAME:$(pg_md5 $PG_PASSWORD)" > /etc/pgpool-II-96/pcp.conf
#export PCPPASSFILE=/tmp/.pcppass
echo "*:*:$PG_USERNAME:$PG_PASSWORD" > /tmp/.pcppass
chmod 0600 /tmp/.pcppass

# Start pgpool
pgpool -n -a $CONFIGS/pool_hba.conf -f $CONFIGS/pgpool.conf  &
export PGPOOL_PID=$!

# Failover
sleep 30
while pgrep -F /tmp/pgpool.pid > /dev/null
do
	bash /opt/cpm/bin/failover.sh
	sleep $TIME_FAILOVER
done

#pgpool -f /tmp/pgpool.conf  reload

echo "waiting for pgpool to be signaled..."
wait