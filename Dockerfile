FROM java:openjdk-7-jre

MAINTAINER zsx <thinkernel@gmail.com>

# Overridable defaults
ENV GERRIT_HOME /var/gerrit
ENV GERRIT_SITE ${GERRIT_HOME}/review_site
ENV GERRIT_WAR ${GERRIT_HOME}/gerrit.war
ENV GERRIT_VERSION 2.12
ENV GERRIT_USER gerrit2
ENV GERRIT_INIT_ARGS ""

# Add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN useradd -m -d "$GERRIT_HOME" -U $GERRIT_USER

# Grab gosu for easy step-down from root
RUN gpg --keyserver pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
	gitweb \
	&& rm -rf /var/lib/apt/lists/* \
	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/1.7/gosu-$(dpkg --print-architecture)" \
	&& wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/1.7/gosu-$(dpkg --print-architecture).asc" \
	&& gpg --verify /usr/local/bin/gosu.asc \
	&& rm /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu

RUN mkdir /docker-entrypoint-init.d

#Download gerrit.war
RUN curl -L https://gerrit-releases.storage.googleapis.com/gerrit-${GERRIT_VERSION}.war -o $GERRIT_WAR
#Only for local test
#COPY gerrit-${GERRIT_VERSION}.war $GERRIT_WAR

#Download Plugins
ENV PLUGIN_VERSION=stable-2.12
ENV GERRITFORGE_URL=https://gerrit-ci.gerritforge.com
ENV GERRITFORGE_ARTIFACT_DIR=lastSuccessfulBuild/artifact/buck-out/gen/plugins
#delete-project
RUN curl \
    -L ${GERRITFORGE_URL}/job/plugin-delete-project-${PLUGIN_VERSION}/${GERRITFORGE_ARTIFACT_DIR}/delete-project/delete-project.jar \
    -o ${GERRIT_HOME}/delete-project.jar

#events-log
#This plugin is required by gerrit-trigger plugin of Jenkins.
RUN curl \
    -L ${GERRITFORGE_URL}/job/plugin-events-log-${PLUGIN_VERSION}/${GERRITFORGE_ARTIFACT_DIR}/events-log/events-log.jar \
    -o ${GERRIT_HOME}/events-log.jar

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

