#!/bin/bash
set -e
#Initialize gerrit if gerrit site dir is empty.
#This is necessary when gerrit site is in a volume.
if [ "$1" = '/var/gerrit/gerrit-start.sh' ]; then
  if [ -z "$(ls -A "$GERRIT_SITE")" ]; then
    echo "First time initialize gerrit..."
    java -jar $GERRIT_WAR init --batch --no-auto-start -d $GERRIT_SITE
  fi

  #Customize gerrit.config
  #mkdir $GERRIT_SITE/etc

  #Section gerrit
  [ -z $WEBURL ] || git config -f $GERRIT_SITE/etc/gerrit.config gerrit.canonicalWebUrl $WEBURL

  #Section database
  if [ $DATABASE_TYPE = 'postgresql' ]; then
    git config -f $GERRIT_SITE/etc/gerrit.config database.type $DATABASE_TYPE
    [ -z $DB_PORT_5432_TCP_ADDR ] || git config -f $GERRIT_SITE/etc/gerrit.config database.hostname $DB_PORT_5432_TCP_ADDR
    [ -z $DB_PORT_5432_TCP_PORT ] || git config -f $GERRIT_SITE/etc/gerrit.config database.port $DB_PORT_5432_TCP_PORT
    [ -z $DB_ENV_POSTGRES_DB ] || git config -f $GERRIT_SITE/etc/gerrit.config database.database $DB_ENV_POSTGRES_DB
    [ -z $DB_ENV_POSTGRES_USER ] || git config -f $GERRIT_SITE/etc/gerrit.config database.username $DB_ENV_POSTGRES_USER
    [ -z $DB_ENV_POSTGRES_PASSWORD ] || git config -f $GERRIT_SITE/etc/secure.config database.password $DB_ENV_POSTGRES_PASSWORD
  fi

  #Section ldap
  if [ $AUTH_TYPE = 'LDAP' ]; then
    git config -f $GERRIT_SITE/etc/gerrit.config auth.type $AUTH_TYPE
    git config -f $GERRIT_SITE/etc/gerrit.config ldap.server ldap://$LDAP_HOST
    git config -f $GERRIT_SITE/etc/gerrit.config ldap.accountBase $LDAP_ACCOUNTBASE
  fi

  echo "Upgrading gerrit..."
  java -jar $GERRIT_WAR init --batch -d $GERRIT_SITE
  if [ $? -eq 0 ]; then
    echo "Upgrading is OK."
  else
    echo "Something wrong..."
    cat $GERRIT_SITE/logs/error_log
  fi
fi
exec "$@"
