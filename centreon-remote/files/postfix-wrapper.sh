#!/usr/bin/env sh
# postfix-wrapper.sh, version 0.1.0
#
# You cannot start postfix in some foreground mode and
# it's more or less important that docker doesn't kill
# postfix and its chilren if you stop the container.
#
# Use this script with supervisord and it will take
# care about starting and stopping postfix correctly.
#
# supervisord config snippet for postfix-wrapper:
#
# [program:postfix]
# process_name = postfix
# command = /path/to/postfix-wrapper.sh
# startsecs = 0
# autorestart = false
#

trap "postfix stop" SIGINT
trap "postfix stop" SIGTERM
trap "postfix reload" SIGHUP

# force new copy of hosts there (otherwise links could be outdated)
mkdir -p /var/spool/postfix/etc
cp /etc/hosts /var/spool/postfix/etc/hosts

# set inet_interfaces to all
sed -i 's/inet_interfaces = localhost/inet_interfaces = all/g' /etc/postfix/main.cf

# start postfix
postfix start

# lets give postfix some time to start
sleep 3

# wait until postfix is dead (triggered by trap)
while kill -0 "`cat /var/spool/postfix/pid/master.pid`"; do
  sleep 5
done
