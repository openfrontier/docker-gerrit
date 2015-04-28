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
    git config -f "${GERRIT_SITE}/etc/gerrit.config" auth.gitBasicAuth true
    [ -z "${LDAP_SERVER}" ] || git config -f "${GERRIT_SITE}/etc/gerrit.config" ldap.server "ldap://${LDAP_SERVER}"
    [ -z "${LDAP_SSLVERIFY}" ] || git config -f "${GERRIT_SITE}/etc/gerrit.config" ldap.sslVerify "${LDAP_SSLVERIFY}"
    [ -z "${LDAP_GROUPSVISIBLETOALL}" ] || git config -f "${GERRIT_SITE}/etc/gerrit.config" ldap.groupsVisibleToAll "${LDAP_GROUPSVISIBLETOALL}"
    [ -z "${LDAP_USERNAME}" ] || git config -f "${GERRIT_SITE}/etc/gerrit.config" ldap.username "${LDAP_USERNAME}"
    [ -z "${LDAP_PASSWORD}" ] || git config -f "${GERRIT_SITE}/etc/gerrit.config" ldap.password "${LDAP_PASSWORD}"
    [ -z "${LDAP_REFERRAL}" ] || git config -f "${GERRIT_SITE}/etc/gerrit.config" ldap.referral "${LDAP_REFERRAL}"
    [ -z "${LDAP_READTIMEOUT}" ] || git config -f "${GERRIT_SITE}/etc/gerrit.config" ldap.readTimeout "${LDAP_READTIMEOUT}"
    [ -z "${LDAP_ACCOUNTBASE}" ] || git config -f "${GERRIT_SITE}/etc/gerrit.config" ldap.accountBase "${LDAP_ACCOUNTBASE}"
    [ -z "${LDAP_ACCOUNTSCOPE}" ] || git config -cd  "${GERRIT_SITE}/etc/gerrit.config" ldap.accountScope "${LDAP_ACCOUNTSCOPE}"
    [ -z "${LDAP_ACCOUNTPATTERN}" ] || git config -f "${GERRIT_SITE}/etc/gerrit.config" ldap.accountPattern "${LDAP_ACCOUNTPATTERN}"
    [ -z "${LDAP_ACCOUNTFULLNAME}" ] || git config -f "${GERRIT_SITE}/etc/gerrit.config" ldap.accountFullName "${LDAP_ACCOUNTFULLNAME}"
    [ -z "${LDAP_ACCOUNTEMAILADDRESS}" ] || git config -f "${GERRIT_SITE}/etc/gerrit.config" ldap.accountEmailAddress "${LDAP_ACCOUNTEMAILADDRESS}"
    [ -z "${LDAP_ACCOUNTSSHUSERNAME}" ] || git config -f "${GERRIT_SITE}/etc/gerrit.config" ldap.accountSshUserName "${LDAP_ACCOUNTSSHUSERNAME}"
    [ -z "${LDAP_ACCOUNTMEMBERFIELD}" ] || git config -f "${GERRIT_SITE}/etc/gerrit.config" ldap.accountMemberField "${LDAP_ACCOUNTMEMBERFIELD}"
    [ -z "${LDAP_FETCHMEMBEROFEAGERLY}" ] || git config -f "${GERRIT_SITE}/etc/gerrit.config" ldap.fetchMemberOfEagerly "${LDAP_FETCHMEMBEROFEAGERLY}"
    [ -z "${LDAP_GROUPBASE}" ] || git config -f "${GERRIT_SITE}/etc/gerrit.config" ldap.groupBase "${LDAP_GROUPBASE}"
    [ -z "${LDAP_GROUPSCOPE}" ] || git config -f "${GERRIT_SITE}/etc/gerrit.config" ldap.groupScope "${LDAP_GROUPSCOPE}"
    [ -z "${LDAP_GROUPPATTERN}" ] || git config -f "${GERRIT_SITE}/etc/gerrit.config" ldap.groupPattern "${LDAP_GROUPPATTERN}"
    [ -z "${LDAP_GROUPMEMBERPATTERN}" ] || git config -f "${GERRIT_SITE}/etc/gerrit.config" ldap.groupMemberPattern "${LDAP_GROUPMEMBERPATTERN}"
    [ -z "${LDAP_GROUPNAME}" ] || git config -f "${GERRIT_SITE}/etc/gerrit.config" ldap.groupName "${LDAP_GROUPNAME}"
    [ -z "${LDAP_LOCALUSERNAMETOLOWERCASE}" ] || git config -f "${GERRIT_SITE}/etc/gerrit.config" ldap.localUsernameToLowerCase "${LDAP_LOCALUSERNAMETOLOWERCASE}"
    [ -z "${LDAP_AUTHENTICATION}" ] || git config -f "${GERRIT_SITE}/etc/gerrit.config" ldap.authentication "${LDAP_AUTHENTICATION}"
    [ -z "${LDAP_USECONNECTIONPOOLING}" ] || git config -f "${GERRIT_SITE}/etc/gerrit.config" ldap.useConnectionPooling "${LDAP_USECONNECTIONPOOLING}"
    [ -z "${LDAP_CONNECTTIMEOUT}" ] || git config -f "${GERRIT_SITE}/etc/gerrit.config" ldap.connectTimeout "${LDAP_CONNECTTIMEOUT}"
  fi

  # section container
  [ -z "${JAVA_HEAPLIMIT}" ] || git config -f "${GERRIT_SITE}/etc/gerrit.config" container.heapLimit "${JAVA_HEAPLIMIT}"
  [ -z "${JAVA_OPTIONS}" ] || git config -f "${GERRIT_SITE}/etc/gerrit.config" container.javaOptions "${JAVA_OPTIONS}"
  [ -z "${JAVA_SLAVE}" ] || git config -f "${GERRIT_SITE}/etc/gerrit.config" container.slave "${JAVA_SLAVE}"

  #Section sendemail
  if [ -z "${SMTP_SERVER}" ]; then
    git config -f "${GERRIT_SITE}/etc/gerrit.config" sendemail.enable false
  else
    git config -f "${GERRIT_SITE}/etc/gerrit.config" sendemail.smtpServer "${SMTP_SERVER}"
  fi

  #Section plugins
  git config -f "${GERRIT_SITE}/etc/gerrit.config" plugins.allowRemoteAdmin true

  #Section httpd
  [ -z "${HTTPD_LISTENURL}" ] || git config -f "${GERRIT_SITE}/etc/gerrit.config" httpd.listenUrl "${HTTPD_LISTENURL}"

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
