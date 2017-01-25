#!/usr/bin/env sh
set -e

set_gerrit_config() {
  gosu ${GERRIT_USER} git config -f "${GERRIT_SITE}/etc/gerrit.config" "$@"
}

set_secure_config() {
  gosu ${GERRIT_USER} git config -f "${GERRIT_SITE}/etc/secure.config" "$@"
}

if [ -n "${JAVA_HEAPLIMIT}" ]; then
  JAVA_MEM_OPTIONS="-Xmx${JAVA_HEAPLIMIT}"
fi

#Initialize gerrit if gerrit site dir is empty.
#This is necessary when gerrit site is in a volume.
if [ "$1" = "/gerrit-start.sh" ]; then
  # If you're mounting ${GERRIT_SITE} to your host, you this will default to root.
  # This obviously ensures the permissions are set correctly for when gerrit starts.
  chown -R ${GERRIT_USER} "${GERRIT_SITE}"

  if [ -z "$(ls -A "$GERRIT_SITE")" ]; then
    echo "First time initialize gerrit..."
    gosu ${GERRIT_USER} java ${JAVA_OPTIONS} ${JAVA_MEM_OPTIONS} -jar "${GERRIT_WAR}" init --batch --no-auto-start --skip-plugins -d "${GERRIT_SITE}" ${GERRIT_INIT_ARGS}
    #All git repositories must be removed when database is set as postgres or mysql
    #in order to be recreated at the secondary init below.
    #Or an execption will be thrown on secondary init.
    [ ${#DATABASE_TYPE} -gt 0 ] && rm -rf "${GERRIT_SITE}/git"
  fi

  # Install external plugins
  gosu ${GERRIT_USER} cp -f ${GERRIT_HOME}/delete-project.jar ${GERRIT_SITE}/plugins/delete-project.jar
  gosu ${GERRIT_USER} cp -f ${GERRIT_HOME}/events-log.jar ${GERRIT_SITE}/plugins/events-log.jar

  # Install the Bouncy Castle
  gosu ${GERRIT_USER} cp -f ${GERRIT_HOME}/bcprov-jdk15on-${BOUNCY_CASTLE_VERSION}.jar ${GERRIT_SITE}/lib/bcprov-jdk15on-${BOUNCY_CASTLE_VERSION}.jar
  gosu ${GERRIT_USER} cp -f ${GERRIT_HOME}/bcpkix-jdk15on-${BOUNCY_CASTLE_VERSION}.jar ${GERRIT_SITE}/lib/bcpkix-jdk15on-${BOUNCY_CASTLE_VERSION}.jar

  # Provide a way to customise this image
  echo
  for f in /docker-entrypoint-init.d/*; do
    case "$f" in
      *.sh)    echo "$0: running $f"; source "$f" ;;
      *.nohup) echo "$0: running $f"; nohup  "$f" & ;;
      *)       echo "$0: ignoring $f" ;;
    esac
    echo
  done

  #Customize gerrit.config

  #Section gerrit
  [ -z "${WEBURL}" ] || set_gerrit_config gerrit.canonicalWebUrl "${WEBURL}"
  [ -z "${GITHTTPURL}" ] || set_gerrit_config gerrit.gitHttpUrl "${GITHTTPURL}"

  #Section sshd
  [ -z "${LISTEN_ADDR}" ] || set_gerrit_config sshd.listenAddress "${LISTEN_ADDR}"

  #Section database
  if [ "${DATABASE_TYPE}" = 'postgresql' ]; then
    set_gerrit_config database.type "${DATABASE_TYPE}"
    [ -z "${DB_PORT_5432_TCP_ADDR}" ]    || set_gerrit_config database.hostname "${DB_PORT_5432_TCP_ADDR}"
    [ -z "${DB_PORT_5432_TCP_PORT}" ]    || set_gerrit_config database.port "${DB_PORT_5432_TCP_PORT}"
    [ -z "${DB_ENV_POSTGRES_DB}" ]       || set_gerrit_config database.database "${DB_ENV_POSTGRES_DB}"
    [ -z "${DB_ENV_POSTGRES_USER}" ]     || set_gerrit_config database.username "${DB_ENV_POSTGRES_USER}"
    [ -z "${DB_ENV_POSTGRES_PASSWORD}" ] || set_secure_config database.password "${DB_ENV_POSTGRES_PASSWORD}"
  fi

  #Section database
  if [ "${DATABASE_TYPE}" = 'mysql' ]; then
    set_gerrit_config database.type "${DATABASE_TYPE}"
    [ -z "${DB_PORT_3306_TCP_ADDR}" ] || set_gerrit_config database.hostname "${DB_PORT_3306_TCP_ADDR}"
    [ -z "${DB_PORT_3306_TCP_PORT}" ] || set_gerrit_config database.port "${DB_PORT_3306_TCP_PORT}"
    [ -z "${DB_ENV_MYSQL_DB}" ]       || set_gerrit_config database.database "${DB_ENV_MYSQL_DB}"
    [ -z "${DB_ENV_MYSQL_USER}" ]     || set_gerrit_config database.username "${DB_ENV_MYSQL_USER}"
    [ -z "${DB_ENV_MYSQL_PASSWORD}" ] || set_secure_config database.password "${DB_ENV_MYSQL_PASSWORD}"
  fi

  #Section auth
  [ -z "${AUTH_TYPE}" ]           || set_gerrit_config auth.type "${AUTH_TYPE}"
  [ -z "${AUTH_HTTP_HEADER}" ]    || set_gerrit_config auth.httpHeader "${AUTH_HTTP_HEADER}"
  [ -z "${AUTH_EMAIL_FORMAT}" ]   || set_gerrit_config auth.emailFormat "${AUTH_EMAIL_FORMAT}"
  [ -z "${AUTH_GIT_BASIC_AUTH}" ] || set_gerrit_config auth.gitBasicAuth "${AUTH_GIT_BASIC_AUTH}"

  #Section ldap
  if [ "${AUTH_TYPE}" = 'LDAP' ] || [ "${AUTH_TYPE}" = 'LDAP_BIND' ] || [ "${AUTH_TYPE}" = 'HTTP_LDAP' ]; then
    [ -z "${AUTH_GIT_BASIC_AUTH}" ]           && set_gerrit_config auth.gitBasicAuth true
    [ -z "${LDAP_SERVER}" ]                   || set_gerrit_config ldap.server "${LDAP_SERVER}"
    [ -z "${LDAP_SSLVERIFY}" ]                || set_gerrit_config ldap.sslVerify "${LDAP_SSLVERIFY}"
    [ -z "${LDAP_GROUPSVISIBLETOALL}" ]       || set_gerrit_config ldap.groupsVisibleToAll "${LDAP_GROUPSVISIBLETOALL}"
    [ -z "${LDAP_USERNAME}" ]                 || set_gerrit_config ldap.username "${LDAP_USERNAME}"
    [ -z "${LDAP_PASSWORD}" ]                 || set_secure_config ldap.password "${LDAP_PASSWORD}"
    [ -z "${LDAP_REFERRAL}" ]                 || set_gerrit_config ldap.referral "${LDAP_REFERRAL}"
    [ -z "${LDAP_READTIMEOUT}" ]              || set_gerrit_config ldap.readTimeout "${LDAP_READTIMEOUT}"
    [ -z "${LDAP_ACCOUNTBASE}" ]              || set_gerrit_config ldap.accountBase "${LDAP_ACCOUNTBASE}"
    [ -z "${LDAP_ACCOUNTSCOPE}" ]             || set_gerrit_config ldap.accountScope "${LDAP_ACCOUNTSCOPE}"
    [ -z "${LDAP_ACCOUNTPATTERN}" ]           || set_gerrit_config ldap.accountPattern "${LDAP_ACCOUNTPATTERN}"
    [ -z "${LDAP_ACCOUNTFULLNAME}" ]          || set_gerrit_config ldap.accountFullName "${LDAP_ACCOUNTFULLNAME}"
    [ -z "${LDAP_ACCOUNTEMAILADDRESS}" ]      || set_gerrit_config ldap.accountEmailAddress "${LDAP_ACCOUNTEMAILADDRESS}"
    [ -z "${LDAP_ACCOUNTSSHUSERNAME}" ]       || set_gerrit_config ldap.accountSshUserName "${LDAP_ACCOUNTSSHUSERNAME}"
    [ -z "${LDAP_ACCOUNTMEMBERFIELD}" ]       || set_gerrit_config ldap.accountMemberField "${LDAP_ACCOUNTMEMBERFIELD}"
    [ -z "${LDAP_FETCHMEMBEROFEAGERLY}" ]     || set_gerrit_config ldap.fetchMemberOfEagerly "${LDAP_FETCHMEMBEROFEAGERLY}"
    [ -z "${LDAP_GROUPBASE}" ]                || set_gerrit_config ldap.groupBase "${LDAP_GROUPBASE}"
    [ -z "${LDAP_GROUPSCOPE}" ]               || set_gerrit_config ldap.groupScope "${LDAP_GROUPSCOPE}"
    [ -z "${LDAP_GROUPPATTERN}" ]             || set_gerrit_config ldap.groupPattern "${LDAP_GROUPPATTERN}"
    [ -z "${LDAP_GROUPMEMBERPATTERN}" ]       || set_gerrit_config ldap.groupMemberPattern "${LDAP_GROUPMEMBERPATTERN}"
    [ -z "${LDAP_GROUPNAME}" ]                || set_gerrit_config ldap.groupName "${LDAP_GROUPNAME}"
    [ -z "${LDAP_LOCALUSERNAMETOLOWERCASE}" ] || set_gerrit_config ldap.localUsernameToLowerCase "${LDAP_LOCALUSERNAMETOLOWERCASE}"
    [ -z "${LDAP_AUTHENTICATION}" ]           || set_gerrit_config ldap.authentication "${LDAP_AUTHENTICATION}"
    [ -z "${LDAP_USECONNECTIONPOOLING}" ]     || set_gerrit_config ldap.useConnectionPooling "${LDAP_USECONNECTIONPOOLING}"
    [ -z "${LDAP_CONNECTTIMEOUT}" ]           || set_gerrit_config ldap.connectTimeout "${LDAP_CONNECTTIMEOUT}"
  fi

  #Section OAUTH general
  if [ "${AUTH_TYPE}" = 'OAUTH' ]  ; then
    gosu ${GERRIT_USER} cp -f ${GERRIT_HOME}/gerrit-oauth-provider.jar ${GERRIT_SITE}/plugins/gerrit-oauth-provider.jar
    [ -z "${OAUTH_ALLOW_EDIT_FULL_NAME}" ]     || set_gerrit_config oauth.allowEditFullName "${OAUTH_ALLOW_EDIT_FULL_NAME}"
    [ -z "${OAUTH_ALLOW_REGISTER_NEW_EMAIL}" ] || set_gerrit_config oauth.allowRegisterNewEmail "${OAUTH_ALLOW_REGISTER_NEW_EMAIL}"

    # Google
    [ -z "${OAUTH_GOOGLE_RESTRICT_DOMAIN}" ]   || set_gerrit_config plugin.gerrit-oauth-provider-google-oauth.domain "${OAUTH_GOOGLE_RESTRICT_DOMAIN}"
    [ -z "${OAUTH_GOOGLE_CLIENT_ID}" ]         || set_gerrit_config plugin.gerrit-oauth-provider-google-oauth.client-id "${OAUTH_GOOGLE_CLIENT_ID}"
    [ -z "${OAUTH_GOOGLE_CLIENT_SECRET}" ]     || set_gerrit_config plugin.gerrit-oauth-provider-google-oauth.client-secret "${OAUTH_GOOGLE_CLIENT_SECRET}"
    [ -z "${OAUTH_GOOGLE_LINK_OPENID}" ]       || set_gerrit_config plugin.gerrit-oauth-provider-google-oauth.link-to-existing-openid-accounts "${OAUTH_GOOGLE_LINK_OPENID}"

    # Github
    [ -z "${OAUTH_GITHUB_CLIENT_ID}" ]         || set_gerrit_config plugin.gerrit-oauth-provider-github-oauth.client-id "${OAUTH_GITHUB_CLIENT_ID}"
    [ -z "${OAUTH_GITHUB_CLIENT_SECRET}" ]     || set_gerrit_config plugin.gerrit-oauth-provider-github-oauth.client-secret "${OAUTH_GITHUB_CLIENT_SECRET}"
  fi

  #Section container
  [ -z "${JAVA_HEAPLIMIT}" ] || set_gerrit_config container.heapLimit "${JAVA_HEAPLIMIT}"
  [ -z "${JAVA_OPTIONS}" ]   || set_gerrit_config container.javaOptions "${JAVA_OPTIONS}"
  [ -z "${JAVA_SLAVE}" ]     || set_gerrit_config container.slave "${JAVA_SLAVE}"

  #Section sendemail
  if [ -z "${SMTP_SERVER}" ]; then
    set_gerrit_config sendemail.enable false
  else
    set_gerrit_config sendemail.enable true
    set_gerrit_config sendemail.smtpServer "${SMTP_SERVER}"
    if [ "smtp.gmail.com" = "${SMTP_SERVER}" ]; then
      echo "gmail detected, using default port and encryption"
      set_gerrit_config sendemail.smtpServerPort 587
      set_gerrit_config sendemail.smtpEncryption tls
    fi
    [ -z "${SMTP_SERVER_PORT}" ] || set_gerrit_config sendemail.smtpServerPort "${SMTP_SERVER_PORT}"
    [ -z "${SMTP_USER}" ]        || set_gerrit_config sendemail.smtpUser "${SMTP_USER}"
    [ -z "${SMTP_PASS}" ]        || set_secure_config sendemail.smtpPass "${SMTP_PASS}"
    [ -z "${SMTP_ENCRYPTION}" ]      || set_gerrit_config sendemail.smtpEncryption "${SMTP_ENCRYPTION}"
    [ -z "${SMTP_CONNECT_TIMEOUT}" ] || set_gerrit_config sendemail.connectTimeout "${SMTP_CONNECT_TIMEOUT}"
    [ -z "${SMTP_FROM}" ]            || set_gerrit_config sendemail.from "${SMTP_FROM}"
  fi

  #Section user
    [ -z "${USER_NAME}" ]             || set_gerrit_config user.name "${USER_NAME}"
    [ -z "${USER_EMAIL}" ]            || set_gerrit_config user.email "${USER_EMAIL}"
    [ -z "${USER_ANONYMOUS_COWARD}" ] || set_gerrit_config user.anonymousCoward "${USER_ANONYMOUS_COWARD}"

  #Section plugins
  set_gerrit_config plugins.allowRemoteAdmin true

  #Section plugin events-log
  set_gerrit_config plugin.events-log.storeUrl "jdbc:h2:${GERRIT_SITE}/db/ChangeEvents"

  #Section httpd
  [ -z "${HTTPD_LISTENURL}" ] || set_gerrit_config httpd.listenUrl "${HTTPD_LISTENURL}"

  #Section gitweb
  set_gerrit_config gitweb.cgi "/usr/share/gitweb/gitweb.cgi"

  echo "Upgrading gerrit..."
  gosu ${GERRIT_USER} java ${JAVA_OPTIONS} ${JAVA_MEM_OPTIONS} -jar "${GERRIT_WAR}" init --batch -d "${GERRIT_SITE}" ${GERRIT_INIT_ARGS}
  if [ $? -eq 0 ]; then
    echo "Reindexing..."
    gosu ${GERRIT_USER} java ${JAVA_OPTIONS} ${JAVA_MEM_OPTIONS} -jar "${GERRIT_WAR}" reindex --verbose -d "${GERRIT_SITE}"
    echo "Upgrading is OK."
  else
    echo "Something wrong..."
    cat "${GERRIT_SITE}/logs/error_log"
  fi
fi
exec "$@"
