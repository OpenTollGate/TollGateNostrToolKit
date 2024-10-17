#!/bin/sh

service network restart
/root/./disable_ipv6.sh
/root/./activate_tollgate.sh
