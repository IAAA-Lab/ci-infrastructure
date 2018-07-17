#!/bin/bash
set -ex

# Give time to ssh-keygen to generate keys before starting sshd
sleep 10s

# Start docker daemon in background
dind dockerd &> /dev/null &

# Ensure variables passed to docker container are also exposed to ssh sessions
env | grep _ >> /etc/environment

# Creates it's own credentials
ssh-keygen -A

# Starts ssh daemon listening to port 22
exec /usr/sbin/sshd -D -e
