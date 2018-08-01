FROM openjdk:8-jre-slim

MAINTAINER zsx <thinkernel@gmail.com>

# Overridable defaults
ENV GERRIT_HOME /var/gerrit
ENV GERRIT_SITE ${GERRIT_HOME}/review_site
ENV GERRIT_WAR ${GERRIT_HOME}/gerrit.war
ENV GERRIT_VERSION 2.14.11
ENV GERRIT_USER gerrit2
ENV GERRIT_INIT_ARGS ""

# Add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN useradd -m -d "${GERRIT_HOME}" -s /usr/sbin/nologin -U "${GERRIT_USER}"

RUN set -x && \
    apt-get update && DEBIAN_FRONTEND=nointeractive apt-get install -y --no-install-recommends \
      curl \
      dirmngr \
      git \
      gitweb \
      gnupg \
      libcgi-pm-perl \
      netcat \
      procmail \
      openssh-client \
      wget

# Install gosu for easy step-down from root
ENV GOSU_VERSION 1.10
RUN set -ex; \
	dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
	wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
	wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
	\
# verify the signature
	export GNUPGHOME="$(mktemp -d)"; \
	key='B42F6819007F00F88E364FD4036A9C25BF357DD4'; \
	gpg --yes --always-trust --keyserver pgp.mit.edu --recv-keys "$key" || \
	gpg --yes --always-trust --keyserver keyserver.pgp.com --recv-keys "$key" || \
	gpg --yes --always-trust --keyserver keyserver.ubuntu.com --recv-keys "$key" || \
	gpg --yes --always-trust --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys "$key" || \
	gpg --yes --always-trust --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
	gpg --yes --always-trust --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
	gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
	rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
	\
	chmod +x /usr/local/bin/gosu; \
# verify that the binary works
	gosu nobody true; \
	\
	apt-get purge -y --auto-remove $fetchDeps
# End install gosu

RUN mkdir /docker-entrypoint-init.d

#Download gerrit.war
RUN wget -O "$GERRIT_WAR" https://gerrit-releases.storage.googleapis.com/gerrit-${GERRIT_VERSION}.war
#Only for local test
#COPY gerrit-${GERRIT_VERSION}.war $GERRIT_WAR

#Download Plugins
ENV PLUGIN_VERSION=bazel-stable-2.14
ENV GERRITFORGE_URL=https://gerrit-ci.gerritforge.com
ENV GERRITFORGE_ARTIFACT_DIR=lastSuccessfulBuild/artifact/bazel-genfiles/plugins

#delete-project
RUN wget -O "${GERRIT_HOME}/delete-project.jar" \
    ${GERRITFORGE_URL}/job/plugin-delete-project-${PLUGIN_VERSION}/${GERRITFORGE_ARTIFACT_DIR}/delete-project/delete-project.jar

#events-log
#This plugin is required by gerrit-trigger plugin of Jenkins.
RUN wget -O "${GERRIT_HOME}/events-log.jar" \
    ${GERRITFORGE_URL}/job/plugin-events-log-${PLUGIN_VERSION}/${GERRITFORGE_ARTIFACT_DIR}/events-log/events-log.jar

#gitiles
RUN wget -O ${GERRIT_HOME}/gitiles.jar \
    ${GERRITFORGE_URL}/job/plugin-gitiles-${PLUGIN_VERSION}/${GERRITFORGE_ARTIFACT_DIR}/gitiles/gitiles.jar

#oauth2 plugin
ENV GERRIT_OAUTH_VERSION 2.14.6

RUN wget -O "${GERRIT_HOME}/gerrit-oauth-provider.jar" \
    https://github.com/davido/gerrit-oauth-provider/releases/download/v${GERRIT_OAUTH_VERSION}/gerrit-oauth-provider.jar

#importer
RUN wget -O "${GERRIT_HOME}/importer.jar" \
    ${GERRITFORGE_URL}/job/plugin-importer-${PLUGIN_VERSION}/${GERRITFORGE_ARTIFACT_DIR}/importer/importer.jar

# Ensure the entrypoint scripts are in a fixed location
COPY gerrit-entrypoint.sh /
COPY gerrit-start.sh /
RUN chmod +x /gerrit*.sh

#A directory has to be created before a volume is mounted to it.
#So gerrit user can own this directory.
RUN gosu ${GERRIT_USER} mkdir -p $GERRIT_SITE

#Gerrit site directory is a volume, so configuration and repositories
#can be persisted and survive image upgrades.
VOLUME $GERRIT_SITE

ENTRYPOINT ["/gerrit-entrypoint.sh"]

EXPOSE 8080 29418

CMD ["/gerrit-start.sh"]
