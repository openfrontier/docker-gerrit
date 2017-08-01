# Gerrit Docker image
 The Gerrit code review system with PostgreSQL and OpenLDAP integration supported.
 This image is based on the Alpine Linux project which makes this image smaller and faster than before.

## Versions

 * openfrontier/gerrit:latest -> 2.14.2
 * openfrontier/gerrit:2.13.x -> 2.13.8
 * openfrontier/gerrit:2.12.x -> 2.12.7
 * openfrontier/gerrit:2.11.x -> 2.11.10
 * openfrontier/gerrit:2.10.x -> 2.10.6

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

## Use local directory as the gerrit site storage.

  1. Create a site directory for the gerrit site.

    mkdir ~/gerrit_volume

  2. Initialize and start gerrit using the local directory created above.

    docker run -d -v ~/gerrit_volume:/var/gerrit/review_site -p 8080:8080 -p 29418:29418 openfrontier/gerrit

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

## Run dockerized gerrit with dockerized PostgreSQL and OpenLDAP.

##### All attributes in [gerrit.config ldap section](https://gerrit-review.googlesource.com/Documentation/config-gerrit.html#ldap) are supported.

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
    -e WEB_URL=http://my-gerrit.example.com/
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

## Using gitiles instead of gitweb

  ```shell
    docker run \
    --name gerrit \
    -p 8080:8080 \
    -p 29418:29418 \
    -e GITWEB_TYPE=gitiles \
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

   An example to demonstrate the way of extending this Gerrit container to integrate with Jenkins are located in [openfrontier/gerrit-docker](https://github.com/openfrontier/gerrit-docker) project.

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
