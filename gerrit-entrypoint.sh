#!/bin/bash
set -e
#Initialize gerrit if gerrit site dir is empty.
#This is necessary when gerrit site is in a volume.
if [ "$1" = '/var/gerrit/gerrit-start.sh' ]; then
  if [ -z "$(ls -A "$GERRIT_SITE")" ]; then
    echo "Initializing gerrit..."
    java -jar $GERRIT_WAR init --batch -d $GERRIT_SITE
    if [ $? -eq 0 ]; then
      echo "Initializing OK."
      $GERRIT_SITE/bin/gerrit.sh stop
    else
      echo "Something wrong..."
      cat $GERRIT_SITE/logs/error_log
    fi
  fi
fi
exec "$@"
