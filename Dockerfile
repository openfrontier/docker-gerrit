FROM openjdk:8-jre-alpine

MAINTAINER zsx <thinkernel@gmail.com>

# Overridable defaults
ARG GERRIT_USER=gerrit2
ARG GERRIT_HOME=/var/lib/gerrit
ARG GERRIT_VERSION=2.14.5.1
ARG PLUGIN_VERSION=bazel-stable-2.14
ARG GERRIT_INIT_ARGS=""
ARG GERRIT_OAUTH_VERSION=2.14.3

# Environment to use both at build time and at run time
ENV \
    GERRIT_HOME=$GERRIT_HOME \
    GERRIT_SITE=$GERRIT_HOME/review_site \
    GERRIT_WAR=$GERRIT_HOME/gerrit.war \
    GERRIT_VERSION=$GERRIT_VERSION \
    GERRIT_USER=gerrit2 \
    GERRIT_INIT_ARGS=$GERRIT_INIT_ARGS \
    GERRITFORGE_URL=https://gerrit-ci.gerritforge.com \
    GERRITFORGE_ARTIFACT_DIR=lastSuccessfulBuild/artifact/buck-out/gen/plugins

VOLUME $GERRIT_SITE

ENTRYPOINT ["/gerrit-entrypoint.sh"]

EXPOSE 8080 29418

CMD ["/gerrit-start.sh"]

#Download gerrit.war
ADD https://gerrit-releases.storage.googleapis.com/gerrit-$GERRIT_VERSION.war \
    $GERRIT_WAR

#Download Plugins

#delete-project
ADD $GERRITFORGE_URL/job/plugin-delete-project-$PLUGIN_VERSION/$GERRITFORGE_ARTIFACT_DIR/delete-project/delete-project.jar \
    $GERRIT_SITE/plugins/

#events-log
#This plugin is required by gerrit-trigger plugin of Jenkins.
ADD $GERRITFORGE_URL/job/plugin-events-log-$PLUGIN_VERSION/$GERRITFORGE_ARTIFACT_DIR/events-log/events-log.jar \
    $GERRIT_SITE/plugins/

#importer
ADD $GERRITFORGE_URL/job/plugin-importer-$PLUGIN_VERSION/$GERRITFORGE_ARTIFACT_DIR/importer/importer.jar \
    $GERRIT_SITE/plugins/

#oauth2 plugin
ADD https://github.com/davido/gerrit-oauth-provider/releases/download/v$GERRIT_OAUTH_VERSION/gerrit-oauth-provider.jar \
    $GERRIT_HOME/gerrit-oauth-provider.jar

#gitiles
ADD $GERRITFORGE_URL/job/plugin-gitiles-$PLUGIN_VERSION/$GERRITFORGE_ARTIFACT_DIR/gitiles/gitiles.jar \
    $GERRIT_HOME/gitiles.jar

# Ensure the entrypoint scripts are in a fixed location
COPY gerrit-entrypoint.sh gerrit-start.sh /

SHELL [ "/bin/sh",  "-euxc" ]

RUN \
    apk add --update --no-cache git openssh openssl bash perl perl-cgi git-gitweb curl su-exec mysql-client ; \
    adduser -D -h "$GERRIT_HOME" -g "Gerrit User" -s /sbin/nologin "$GERRIT_USER" ; \
    mkdir /docker-entrypoint-init.d ; \
    chmod +x /gerrit*.sh ; \
    chown -R "$GERRIT_USER" "$GERRIT_SITE" "$GERRIT_HOME"
