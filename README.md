# Gerrit Docker image

[![Docker Stars](https://img.shields.io/docker/stars/openfrontier/gerrit.svg)](https://hub.docker.com/r/openfrontier/gerrit/)
[![Docker Pulls](https://img.shields.io/docker/pulls/openfrontier/gerrit.svg)](https://hub.docker.com/r/openfrontier/gerrit/)
[![Docker Automated build](https://img.shields.io/docker/automated/openfrontier/gerrit.svg)](https://hub.docker.com/r/openfrontier/gerrit/)

 The Gerrit code review system with external database and OpenLDAP integration.
 This image is based on the openjdk:jre-alpine or the openjdk:jre-slim which makes this image small and fast.

## Branches and Tags

 The `latest` is not production ready because new features will be tested on it first.
 The branch tags like `2.14.x` or `2.15.x` are used to track the releases of Gerrit. Approved new features will be merged to these branches first then included in the next [release](https://github.com/openfrontier/docker-gerrit/releases).

#### Alpine base

 * openfrontier/gerrit:2.16.x -> 2.16.17

#### Debian base

 * Unsupported yet, depends on community needs.

## Migrate from ReviewDB to NoteDB
  Since Gerrit 2.16, [NoteDB](https://gerrit-review.googlesource.com/Documentation/note-db.html) is required to store accounts and groups data.
  Changes are strongly advised to migrate to NoteDB, too.
  Accounts and Groups are migrated offline to NoteDB automatically during the start up of the container.
  Change data can be migrated to NoteDB offline via the `MIGRATE_TO_NOTEDB_OFFLINE` environment variable.
  Note that migrating changes can takes about twice as long as an offline reindex. In fact, one of the
  migration steps is a full reindex, so it can't possibly take less time.

  ```shell
    docker run \
        -e MIGRATE_TO_NOTEDB_OFFLINE=true \
        -v ~/gerrit_volume:/var/gerrit/review_site \
        -p 8080:8080 \
        -p 29418:29418 \
        -d openfrontier/gerrit
  ```
  Online migration of change data is also available via the `NOTEDB_CHANGES_AUTOMIGRATE` environment variable.

  ```shell
    docker run \
        -e NOTEDB_CHANGES_AUTOMIGRATE=true \
        -v ~/gerrit_volume:/var/gerrit/review_site \
        -p 8080:8080 \
        -p 29418:29418 \
        -d openfrontier/gerrit
  ```
  This feature is only available in Gerrit version 2.15 and above.

## Container Quickstart

  1. Initialize and start gerrit.

    docker run -d -p 8080:8080 -p 29418:29418 openfrontier/gerrit

  2. Open your browser to http://<docker host url>:8080

## Use HTTP authentication type

    docker run -d -p 8080:8080 -p 29418:29418 -e AUTH_TYPE=HTTP openfrontier/gerrit

## Use another container as the gerrit site storage.

  1. Create a volume container.

    docker run --name gerrit_volume openfrontier/gerrit echo "Gerrit volume container."

  2. Initialize and start gerrit using volume created above.

    docker run -d --volumes-from gerrit_volume -p 8080:8080 -p 29418:29418 openfrontier/gerrit

## Use a docker named volume as the gerrit site storage.
  **DO NOT** use host volumes in particular directories under the home directory like `~/gerrit` as a gerrit volume!!! Use [named volume](https://success.docker.com/article/different-types-of-volumes) instead!!!

  1. Create a docker volume for the gerrit site.

    docker volume create gerrit_volume

  2. Initialize and start gerrit using the local directory created above.

    docker run -d -v gerrit_volume:/var/gerrit/review_site -p 8080:8080 -p 29418:29418 openfrontier/gerrit

## Install plugins on start up.

  When calling gerrit init --batch, it is possible to list plugins to be installed with --install-plugin=<plugin_name>. This can be done using the GERRIT_INIT_ARGS environment variable. See [Gerrit Documentation](https://gerrit-review.googlesource.com/Documentation/pgm-init.html) for more information.

    #Install download-commands plugin on start up
    docker run -d -p 8080:8080 -p 29418:29418 -e GERRIT_INIT_ARGS='--install-plugin=download-commands' openfrontier/gerrit

## Extend this image.

  Similarly to the [Postgres](https://hub.docker.com/_/postgres/) image, if you would like to do additional configuration mid-script, add one or more
  `*.sh` or `*.nohup` scripts under `/docker-entrypoint-init.d`. This directory is created by default. Scripts in `/docker-entrypoint-init.d` are run after
  gerrit has been initialized, but before any of the gerrit config is customized, allowing you to programmatically override environment variables in entrypoint
  scripts. `*.nohup` scripts are run into the background with nohup command.

  You can also extend the image with a simple `Dockerfile`. The following example will add some scripts to initialize the container on start up.

  ```dockerfile
  FROM openfrontier/gerrit:latest

  COPY gerrit-create-user.sh /docker-entrypoint-init.d/gerrit-create-user.sh
  COPY gerrit-upload-ssh-key.sh /docker-entrypoint-init.d/gerrit-upload-ssh-key.sh
  COPY gerrit-init.nohup /docker-entrypoint-init.d/gerrit-init.nohup
  RUN chmod +x /docker-entrypoint-init.d/*.sh /docker-entrypoint-init.d/*.nohup
  ```

## Run dockerized gerrit with external database and OpenLDAP.

##### All attributes in [gerrit.config database section](https://gerrit-review.googlesource.com/Documentation/config-gerrit.html#database) are supported.

##### All attributes in [gerrit.config ldap section](https://gerrit-review.googlesource.com/Documentation/config-gerrit.html#ldap) are supported.

  ```shell
    #Start gerrit docker to connect with an already existed postgres.
    docker run \
    --name gerrit \
    -p 8080:8080 \
    -p 29418:29418 \
    -e WEBURL=http://your.site.domain:8080 \
    -e DATABASE_TYPE=postgresql \
    -e DATABASE_HOSTNAME=postgres.hostname \
    -e DATABASE_PORT=5432 \
    -e DATABASE_DATABASE=reviewdb \
    -e DATABASE_USERNAME=gerrit2 \
    -e DATABASE_PASSWORD=gerrit \
    -e AUTH_TYPE=LDAP \
    -e LDAP_SERVER=ldap://ldap.server.address \
    -e LDAP_ACCOUNTBASE=<ldap-basedn> \
    -d openfrontier/gerrit
  ```

## Run dockerized gerrit with dockerized PostgreSQL and OpenLDAP.

#### Note: docker --link is deprecated and this way might be unsupported in the future release.

  ```shell
    # Start postgres docker
    docker run \
    --name pg-gerrit \
    -p 5432:5432 \
    -e POSTGRES_USER=gerrit2 \
    -e POSTGRES_PASSWORD=gerrit \
    -e POSTGRES_DB=reviewdb \
    -d postgres
    #Start gerrit docker ( AUTH_TYPE=HTTP_LDAP is also supported )
    docker run \
    --name gerrit \
    --link pg-gerrit:db \
    -p 8080:8080 \
    -p 29418:29418 \
    -e WEBURL=http://your.site.domain:8080 \
    -e DATABASE_TYPE=postgresql \
    -e AUTH_TYPE=LDAP \
    -e LDAP_SERVER=ldap://ldap.server.address \
    -e LDAP_ACCOUNTBASE=<ldap-basedn> \
    -d openfrontier/gerrit
  ```

## Setup sendemail options.

##### Some basic attributes in [gerrit.config sendmail section](https://gerrit-review.googlesource.com/Documentation/config-gerrit.html#sendemail) are supported.

  ```shell
    #Start gerrit docker with sendemail supported.
    #All SMTP_* attributes are optional.
    #Sendemail function will be disabled if SMTP_SERVER is not specified.
    docker run \
    --name gerrit \
    -p 8080:8080 \
    -p 29418:29418 \
    -e WEBURL=http://your.site.domain:8080 \
    -e SMTP_SERVER=smtp.server.address \
    -e SMTP_SERVER_PORT=25 \
    -e SMTP_ENCRYPTION=tls \
    -e SMTP_USER=<smtp user> \
    -e SMTP_PASS=<smtp password> \
    -e SMTP_CONNECT_TIMEOUT=10sec \
    -e SMTP_FROM=USER \
    -d openfrontier/gerrit
  ```

## Setup user options

##### All attributes in [gerrit.config user section](https://gerrit-review.googlesource.com/Documentation/config-gerrit.html#user) are supported.

  ```shell
    #Start gerrit docker with user info provided.
    #All USER_* attributes are optional.
    docker run \
    --name gerrit \
    -p 8080:8080 \
    -p 29418:29418 \
    -e WEBURL=http://your.site.domain:8080 \
    -e USER_NAME=gerrit \
    -e USER_EMAIL=gerrit@your.site.domain \
    -d openfrontier/gerrit
  ```

## Setup OAUTH options

  ```shell
    docker run \
    --name gerrit \
    -p 8080:8080 \
    -p 29418:29418 \
    -e AUTH_TYPE=OAUTH \
    # Don't forget to set Gerrit FQDN for correct OAuth
    -e WEBURL=http://my-gerrit.example.com \
    -e OAUTH_ALLOW_EDIT_FULL_NAME=true \
    -e OAUTH_ALLOW_REGISTER_NEW_EMAIL=true \
    # Google OAuth
    -e OAUTH_GOOGLE_RESTRICT_DOMAIN=your.site.domain \
    -e OAUTH_GOOGLE_CLIENT_ID=1234567890 \
    -e OAUTH_GOOGLE_CLIENT_SECRET=dakjhsknksbvskewu-googlesecret \
    -e OAUTH_GOOGLE_LINK_OPENID=true \
    # Github OAuth
    -e OAUTH_GITHUB_CLIENT_ID=abcdefg \
    -e OAUTH_GITHUB_CLIENT_SECRET=secret123 \
    # GitLab OAuth
    # How to obtain secrets: https://docs.gitlab.com/ee/integration/oauth_provider.html
    -e OAUTH_GITLAB_ROOT_URL=http://my-gitlab.example.com/ \
    -e OAUTH_GITLAB_CLIENT_ID=abcdefg \
    -e OAUTH_GITLAB_CLIENT_SECRET=secret123 \
    # Bitbucket OAuth
    -e OAUTH_BITBUCKET_CLIENT_ID=abcdefg \
    -e OAUTH_BITBUCKET_CLIENT_SECRET=secret123 \
    -e OAUTH_BITBUCKET_FIX_LEGACY_USER_ID=true \
    -d openfrontier/gerrit
  ```
## Setup Replication to multiple remotes 

  ```shell
    docker run \
    --name gerrit \
    -p 8080:8080 \
    -p 29418:29418 \
    -e WEBURL=http://my-gerrit.example.com \
    -e DOWNLOAD_SCHEMES="http ssh" \
    -e GERRIT_INIT_ARGS="--install-plugin=replication" \
    -e REPLICATION_REMOTES="bitbucket github" \
    -e REPLICATE_ON_STARTUP=true \
    -e REPLICATION_MAX_RETRIES=3 \
    -e BITBUCKET_URL=https://bitbucket.org/${BB_ORG}/${name}.git \
    -e BITBUCKET_PROJECTS="demo* prod*" \
    -e BITBUCKET_USERNAME=${BB_USER} \
    -e BITBUCKET_PASSWORD=${BB_PASSWORD} \
    -e BITBUCKET_MIRROR=true \
    -e BITBUCKET_TIMEOUT=60 \
    -e BITBUCKET_THREADS=2 \
    -e BITBUCKET_RESCHEDULE_DELAY=15 \
    -e BITBUCKET_REPLICATION_DELAY=15 \
    -e BITBUCKET_REPLICATION_RETRY=1 \
    -e BITBUCKET_REPLICATION_MAX_RETRIES=5 \
    -e BITBUCKET_REPLICATE_PERMISSIONS=false \
    -e BITBUCKET_CREATE_MISSING_REPOSITORIES=false \
    -e GITHUB_URL=https://${GH_USER}@github.com/${GH_ORG}/${name}.git \
    -e GITHUB_PASSWORD=${GH_PASSWORD} \
    -d openfrontier/gerrit
  ```

## Using gitiles instead of gitweb

  ```shell
    docker run \
    --name gerrit \
    -p 8080:8080 \
    -p 29418:29418 \
    -e GITWEB_TYPE=gitiles \
    -d openfrontier/gerrit
  ```

## Restricting download schemes  

  ```shell
    docker run \
    --name gerrit \
    -p 8080:8080 \
    -p 29418:29418 \
    -e DOWNLOAD_SCHEMES=http ssh \
    -d openfrontier/gerrit
  ```

## Setup DEVELOPMENT_BECOME_ANY_ACCOUNT option

**DO NOT USE.** Only for use in a development environment.
When this is the configured authentication method a hyperlink titled "Become" appears in the top right corner of the page, taking the user to a form where they can enter the username of any existing user account, and immediately login as that account, without any authentication taking place. This form of authentication is only useful for the GWT hosted mode shell, where OpenID authentication redirects might be risky to the developer's host computer, and HTTP authentication is not possible.

  ```shell
    docker run \
    --name gerrit \
    -p 8080:8080 \
    -p 29418:29418 \
    -e AUTH_TYPE=DEVELOPMENT_BECOME_ANY_ACCOUNT \
    -d openfrontier/gerrit
  ```

## Override the default startup action

Gerrit is launched using the `daemon` action of its init script.  This
brings the server up without forking and sends error log messages to the
console.  An alternative is to start Gerrit using `supervise` which is
very similar to `daemon` except that error log messages are persisted to
`${GERRIT_SITE}/logs/error_log`.

Gerrit can be started with a non-default action using the
`GERRIT_START_ACTION` environment variable.  For example, Gerrit can be
started with `supervise` as follows:

  ```shell
    docker run \
        -e GERRIT_START_ACTION=supervise \
        -v ~/gerrit_volume:/var/gerrit/review_site \
        -p 8080:8080 \
        -p 29418:29418 \
        -d openfrontier/gerrit
  ```

**NOTE:** Not all init actions make sense for starting Gerrit in a Docker
container.  Specifically, invoking Gerrit with `start` forks the server
before returning which will cause the container to exit soon after.

## Sample operational scripts

   An example to demonstrate how to extend this Gerrit image to integrate with Jenkins are located in the [openfrontier/gerrit-ci](https://hub.docker.com/r/openfrontier/gerrit-ci/) .

   A Jenkins docker image with some sample scripts to integrate with this Gerrit image can be pulled from [openfrontier/jenkins](https://hub.docker.com/r/openfrontier/jenkins/).

   There's an [upper project](https://github.com/openfrontier/ci) which privdes sample scripts about how to use this image and a [Jenkins image](https://hub.docker.com/r/openfrontier/jenkins/) to create a Gerrit-Jenkins integration environment. And there's a [compose project](https://github.com/openfrontier/ci-compose) to demonstrate how to utilize docker compose to accomplish the same thing.

## Sync timezone with the host server.

    docker run -d -p 8080:8080 -p 29418:29418 -v /etc/localtime:/etc/localtime:ro openfrontier/gerrit

## Automatic reindex detection

  The docker container automatically writes the current gerrit version into `${GERRIT_HOME}/review_site/gerrit_version`
  in order to detect whether a full upgrade should be performed.
  This check can be disabled via the `IGNORE_VERSIONCHECK` environment variable.

  Note that for major version upgrades a full reindex might be necessary. Check the gerrit upgrade notes for details.
  For large repositories, the full reindex can take 30min or more.

  ```shell
    docker run \
        -e IGNORE_VERSIONCHECK=1 \
        -v ~/gerrit_volume:/var/gerrit/review_site \
        -p 8080:8080 \
        -p 29418:29418 \
        -d openfrontier/gerrit
  ```
