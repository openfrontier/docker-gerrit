#!/bin/bash
set -e
#Initialize gerrit if gerrit site dir is empty.
#This is necessary when gerrit site is in a volume.
if [ "$1" = '/var/gerrit/gerrit-start.sh' ]; then
  if [ -z "$(ls -A "$GERRIT_SITE")" ]; then
    #Customize gerrit.config
    mkdir $GERRIT_SITE/etc

    #Section gerrit
    [ -z $CANONICAL_WEBURL ] || git config -f $GERRIT_SITE/etc/gerrit.config gerrit.canonicalWebUrl $CANONICAL_WEBURL

    #Section database
    [ -z $DATABASE_TYPE ] || git config -f $GERRIT_SITE/etc/gerrit.config database.type $DATABASE_TYPE
    [ -z $DATABASE_HOSTNAME ] || git config -f $GERRIT_SITE/etc/gerrit.config database.hostname $DATABASE_HOSTNAME
    [ -z $DATABASE_DATABASE ] || git config -f $GERRIT_SITE/etc/gerrit.config database.database $DATABASE_DATABASE
    [ -z $DATABASE_USERNAME ] || git config -f $GERRIT_SITE/etc/secure.config database.username $DATABASE_USERNAME
    [ -z $DATABASE_PASSWORD ] || git config -f $GERRIT_SITE/etc/secure.config database.password $DATABASE_PASSWORD

    echo "Initializing gerrit..."
    java -jar $GERRIT_WAR init --no-auto-start -d $GERRIT_SITE
    if [ $? -eq 0 ]; then
      echo "Initializing OK."
    else
      echo "Something wrong..."
      cat $GERRIT_SITE/logs/error_log
    fi
  fi
fi
exec "$@"
