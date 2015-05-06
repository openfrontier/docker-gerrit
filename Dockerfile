FROM java:openjdk-7-jre

MAINTAINER zsx <thinkernel@gmail.com>

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    libcgi-pm-perl \
    gitweb \
  && rm -rf /var/lib/apt/lists/*
ENV GERRIT_HOME /var/gerrit
ENV GERRIT_SITE ${GERRIT_HOME}/review_site
ENV GERRIT_WAR ${GERRIT_HOME}/gerrit.war
ENV GERRIT_VERSION 2.10.3.1
ENV GERRIT_USER gerrit2

RUN useradd -m -d "$GERRIT_HOME" -u 1000 -U  -s /bin/bash $GERRIT_USER

#Download gerrit.war
RUN curl -L https://gerrit-releases.storage.googleapis.com/gerrit-${GERRIT_VERSION}.war -o $GERRIT_WAR
#Only for local test
#COPY gerrit-${GERRIT_VERSION}.war $GERRIT_WAR

COPY gerrit-entrypoint.sh ${GERRIT_HOME}/
COPY gerrit-start.sh ${GERRIT_HOME}/

RUN chmod +x ${GERRIT_HOME}/gerrit*.sh

USER $GERRIT_USER

#A directory has to be created before a volume is mounted to it.
#So gerrit user can own this directory.
RUN mkdir -p $GERRIT_SITE

#Gerrit site directory is a volume, so configuration and repositories
#can be persisted and survive image upgrades.
VOLUME $GERRIT_SITE

ENTRYPOINT ["/var/gerrit/gerrit-entrypoint.sh"]

EXPOSE 8080 29418

CMD ["/var/gerrit/gerrit-start.sh"]

