#!/bin/bash

. /gcsdk/google-cloud-sdk/path.bash.inc

sudo -E /usr/local/share/slurm_gcp_docker/src/docker_copy_gcloud_credentials.sh

sudo mysqld &
/usr/local/share/slurm_gcp_docker/src/provision_server.py
# export SLURM_CONF=/usr/local/etc/slurm.conf # In Dockerfile, we used --sysconfdir=/usr/local/etc, we probably don't need to set this environment

/bin/bash
