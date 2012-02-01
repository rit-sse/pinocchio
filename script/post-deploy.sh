#!/bin/bash

# bundle our gems for deployment with binstubs, and the ruby-local-exec shebang
#
# we used to use --deployment, but it's sloooowww and can cause problems with
# deploying, oddly enough...
bundle install --quiet --binstubs --shebang ruby-local-exec

# gracefully reload app with unicorn magic
pid=/home/deploy/pinocchio/tmp/pids/unicorn.pid
test -s $pid && kill -s USR2 "$(cat $pid)"

if [[ "$?" -ne "0" ]] ; then
  echo "ERROR: Failed to restart Unicorn. Pidfile likely doesn't exist." 2>&1
fi

# SRSLY THAT'S IT?
# ...yep.
