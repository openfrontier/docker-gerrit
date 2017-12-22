#!/usr/bin/env sh
set -e
echo "Starting Gerrit..."
exec gosu ${GERRIT_USER} ${GERRIT_SITE}/bin/gerrit.sh ${GERRIT_START_ACTION:-daemon}
