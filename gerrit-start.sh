#!/bin/bash
set -e
#TODO:Not sure if gerrit can be stopped properly...
echo "Starting Gerrit..."
$GERRIT_SITE/bin/gerrit.sh daemon
if [ $? -eq 0 ]; then
  tail -f $GERRIT_SITE/logs/httpd_log
else
  cat $GERRIT_SITE/logs/error_log
fi
