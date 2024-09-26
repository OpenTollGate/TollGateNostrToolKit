#!/bin/sh

if [ ! -f /etc/first_login_done ] && [ -t 0 ] && [ -t 1 ]; then
    echo "Running first login setup..."
    /usr/local/bin/first-login-setup
fi
