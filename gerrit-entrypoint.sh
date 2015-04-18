#!/bin/bash
set -e
#Initialize gerrit if gerrit site dir is empty.
#This is necessary when gerrit site is in a volume.
if [ "$1" = '/var/gerrit/gerrit-start.sh' ]; then
  if [ -z "$(ls -A "$GERRIT_SITE")" ]; then
    echo "First time initialize gerrit..."
    java -jar "${GERRIT_WAR}" init --batch --no-auto-start -d "${GERRIT_SITE}"
    #All git repositories must be removed in order to be recreated at the secondary init below.
    rm -rf "${GERRIT_SITE}/git"
  fi

  #Customize gerrit.config

  #Section gerrit
  [ -z "${WEBURL}" ] || git config -f "${GERRIT_SITE}/etc/gerrit.config" gerrit.canonicalWebUrl "${WEBURL}"

  #Section database
  if [ "${DATABASE_TYPE}" = 'postgresql' ]; then
    git config -f "${GERRIT_SITE}/etc/gerrit.config" database.type "${DATABASE_TYPE}"
    [ -z "${DB_PORT_5432_TCP_ADDR}" ] || git config -f "${GERRIT_SITE}/etc/gerrit.config" database.hostname "${DB_PORT_5432_TCP_ADDR}"
    [ -z "${DB_PORT_5432_TCP_PORT}" ] || git config -f "${GERRIT_SITE}/etc/gerrit.config" database.port "${DB_PORT_5432_TCP_PORT}"
    [ -z "${DB_ENV_POSTGRES_DB}" ] || git config -f "${GERRIT_SITE}/etc/gerrit.config" database.database "${DB_ENV_POSTGRES_DB}"
    [ -z "${DB_ENV_POSTGRES_USER}" ] || git config -f "${GERRIT_SITE}/etc/gerrit.config" database.username "${DB_ENV_POSTGRES_USER}"
    [ -z "${DB_ENV_POSTGRES_PASSWORD}" ] || git config -f "${GERRIT_SITE}/etc/secure.config" database.password "${DB_ENV_POSTGRES_PASSWORD}"
  fi

  #Section ldap
  if [ "${AUTH_TYPE}" = 'LDAP' ]; then
    git config -f "${GERRIT_SITE}/etc/gerrit.config" auth.type "${AUTH_TYPE}"
    [ -z "${LDAP_HOST}" ] || git config -f "${GERRIT_SITE}/etc/gerrit.config" ldap.server "ldap://${LDAP_HOST}"
    [ -z "${LDAP_ACCOUNTBASE}" ] || git config -f "${GERRIT_SITE}/etc/gerrit.config" ldap.accountBase "${LDAP_ACCOUNTBASE}"
    [ -z "${LDAP_GROUPBASE}" ] || git config -f "${GERRIT_SITE}/etc/gerrit.config" ldap.groupBase "${LDAP_GROUPBASE}"
    [ -z "${LDAP_USER}" ] || git config -f "${GERRIT_SITE}/etc/gerrit.config" ldap.user "${LDAP_USER}"
    [ -z "${LDAP_PASSWORD}" ] || git config -f "${GERRIT_SITE}/etc/gerrit.config" ldap.password "${LDAP_PASSWORD}"
  fi

  #Section sendemail
  if [ -z "${SMTP_SERVER}" ]; then
    git config -f "${GERRIT_SITE}/etc/gerrit.config" sendemail.enable false
  else
    git config -f "${GERRIT_SITE}/etc/gerrit.config" sendemail.smtpServer "${SMTP_SERVER}"
  fi

  #Section plugins
  git config -f "${GERRIT_SITE}/etc/gerrit.config" plugins.allowRemoteAdmin true

  echo "Upgrading gerrit..."
  java -jar "${GERRIT_WAR}" init --batch -d "${GERRIT_SITE}"
  if [ $? -eq 0 ]; then
    echo "Upgrading is OK."
  else
    echo "Something wrong..."
    cat "${GERRIT_SITE}/logs/error_log"
  fi
fi
exec "$@"
