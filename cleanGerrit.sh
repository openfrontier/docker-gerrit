#!/bin/bash
set -e
LOCAL_VOLUME='/home/admin/gerrit_volume'
GERRIT_DOCKER_NAME=gerrit
PG_DOCKER_NAME=pg-gerrit
docker rm -f $GERRIT_DOCKER_NAME
docker stop $PG_DOCKER_NAME
docker rm -v $PG_DOCKER_NAME
rm -rf $LOCAL_VOLUME
