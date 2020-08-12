FROM openjdk:8-jre-alpine

MAINTAINER zsx <thinkernel@gmail.com>

# Overridable defaults
ENV GERRIT_HOME /var/gerrit
ENV GERRIT_SITE ${GERRIT_HOME}/review_site
ENV GERRIT_WAR ${GERRIT_HOME}/gerrit.war
ENV GERRIT_VERSION 3.1.8
ENV GERRIT_USER gerrit2
ENV GERRIT_INIT_ARGS "--install-plugin=delete-project --install-plugin=gitiles --install-plugin=plugin-manager"

# Add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN adduser -D -h "${GERRIT_HOME}" -g "Gerrit User" -s /sbin/nologin "${GERRIT_USER}"

RUN set -x \
    && apk add --update --no-cache git openssh-client openssl bash perl perl-cgi git-gitweb curl su-exec procmail

RUN mkdir /docker-entrypoint-init.d

#Download gerrit.war
RUN curl -fSsL https://gerrit-releases.storage.googleapis.com/gerrit-${GERRIT_VERSION}.war -o $GERRIT_WAR
#Only for local test
#COPY gerrit-${GERRIT_VERSION}.war $GERRIT_WAR

#Download Plugins
ENV PLUGIN_VERSION=3.1
ENV GERRITFORGE_URL=https://gerrit-ci.gerritforge.com
ENV GERRITFORGE_ARTIFACT_DIR=lastSuccessfulBuild/artifact/bazel-bin/plugins

#events-log
#This plugin is required by gerrit-trigger plugin of Jenkins.
RUN curl -fSsL \
    ${GERRITFORGE_URL}/job/plugin-events-log-bazel-stable-${PLUGIN_VERSION}/${GERRITFORGE_ARTIFACT_DIR}/events-log/events-log.jar \
    -o ${GERRIT_HOME}/events-log.jar

#oauth2
RUN curl -fSsL \
    ${GERRITFORGE_URL}/job/plugin-oauth-bazel-master-stable-${PLUGIN_VERSION}/${GERRITFORGE_ARTIFACT_DIR}/oauth/oauth.jar \
    -o ${GERRIT_HOME}/oauth.jar

#importer
# Not ready for 3.0
#RUN curl -fSsL \
#    ${GERRITFORGE_URL}/job/plugin-importer-${PLUGIN_VERSION}/${GERRITFORGE_ARTIFACT_DIR}/importer/importer.jar \
#    -o ${GERRIT_HOME}/importer.jar

# Ensure the entrypoint scripts are in a fixed location
COPY gerrit-entrypoint.sh /
COPY gerrit-start.sh /
RUN chmod +x /gerrit*.sh

#A directory has to be created before a volume is mounted to it.
#So gerrit user can own this directory.
RUN su-exec ${GERRIT_USER} mkdir -p $GERRIT_SITE

#Gerrit site directory is a volume, so configuration and repositories
#can be persisted and survive image upgrades.
VOLUME $GERRIT_SITE

ENTRYPOINT ["/gerrit-entrypoint.sh"]

EXPOSE 8080 29418

CMD ["/gerrit-start.sh"]
