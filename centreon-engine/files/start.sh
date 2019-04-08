#!/bin/sh

exec /usr/bin/supervisord -n -u root -c /etc/supervisord.conf

