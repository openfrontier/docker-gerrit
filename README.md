# Gerrit Docker image
 The Gerrit code review system with PostgreSQL and OpenLDAP integration supported.
 This image is based on the Alpine Linux project which makes this image smaller and faster than before.

## Versions
 openfrontier/gerrit:latest -> 2.12.2

 openfrontier/gerrit:2.11.x -> 2.11.8

 openfrontier/gerrit:2.10.x -> 2.10.6

## Container Quickstart
  1. Initialize and start gerrit.

    `docker run -d -p 8080:8080 -p 29418:29418 openfrontier/gerrit`

  2. Open your browser to http://<docker host url>:8080

## Use another container as the gerrit site storage.
  1. Create a volume container.

    `docker run --name gerrit_volume openfrontier/gerrit echo "Gerrit volume container."`

  2. Initialize and start gerrit using volume created above.

    `docker run -d --volumes-from gerrit_volume -p 8080:8080 -p 29418:29418 openfrontier/gerrit`

## Use local directory as the gerrit site storage.
  1. Create a site directory for the gerrit site.

    `mkdir ~/gerrit_volume`

  2. Initialize and start gerrit using the local directory created above.

    `docker run -d -v ~/gerrit_volume:/var/gerrit/review_site -p 8080:8080 -p 29418:29418 openfrontier/gerrit`

## Install plugins on start.
  When calling gerrit init --batch, it is possible to list plugins to be installed with --install-plugin=<plugin_name>. This can be done using the GERRIT_INIT_ARGS environment variable. See [Gerrit Documentation](https://gerrit-review.googlesource.com/Documentation/pgm-init.html) for more information.

     #Install download-commands plugin on start
     docker run -d -p 8080:8080 -p 29418:29418 -e GERRIT_INIT_ARGS='--install-plugin=download-commands' openfrontier/gerrit

## Extend this image.
  Similarly to the [Postgres](https://hub.docker.com/_/postgres/) image, if you would like to do additional configuration mid-script, add one or more
  `*.sh` scripts under `/docker-entrypoint-init.d`. This directory is created by default. Scripts in `/docker-entrypoint-init.d` are run after gerrit
  has been initialized, but before any of the gerrit config is customized, allowing you to programmatically override environment variables in entrypoint
  scripts.

## Run dockerized gerrit with dockerized PostgreSQL and OpenLDAP.
#####All attributes in [gerrit.config ldap section](https://gerrit-review.googlesource.com/Documentation/config-gerrit.html#ldap) are supported.

    #Start postgres docker
    docker run \
    --name pg-gerrit \
    -p 5432:5432 \
    -e POSTGRES_USER=gerrit2 \
    -e POSTGRES_PASSWORD=gerrit \
    -e POSTGRES_DB=reviewdb \
    -d postgres
    #Start gerrit docker
    docker run \
    --name gerrit \
    --link pg-gerrit:db \
    -p 8080:8080 \
    -p 29418:29418 \
    -e WEBURL=http://<your.site.url>:8080 \
    -e DATABASE_TYPE=postgresql \
    -e AUTH_TYPE=LDAP \
    -e LDAP_SERVER=<ldap-servername> \
    -e LDAP_ACCOUNTBASE=<ldap-basedn> \
    -d openfrontier/gerrit

## Setup sendemail options.
#####Some basic attributes in [gerrit.config sendmail section](https://gerrit-review.googlesource.com/Documentation/config-gerrit.html#sendemail) are supported.

    #Start gerrit docker with sendemail supported.
    #All SMTP_* attributes are optional.
    #Sendemail function will be disabled if SMTP_SERVER is not specified.
    docker run \
    --name gerrit \
    -p 8080:8080 \
    -p 29418:29418 \
    -e WEBURL=http://<your.site.url>:8080 \
    -e SMTP_SERVER=<your.smtp.server.url> \
    -e SMTP_SERVER_PORT=25 \
    -e SMTP_ENCRYPTION=tls \
    -e SMTP_USER=<smtp user> \
    -e SMTP_PASS=<smtp password> \
    -e SMTP_CONNECT_TIMEOUT=10sec \
    -e SMTP_FROM=USER \
    -d openfrontier/gerrit

## Setup user options.
#####All attributes in [gerrit.config user section](https://gerrit-review.googlesource.com/Documentation/config-gerrit.html#user) are supported.

    #Start gerrit docker with user info provided.
    #All USER_* attributes are optional.
    docker run \
    --name gerrit \
    -p 8080:8080 \
    -p 29418:29418 \
    -e WEBURL=http://<your.site.url>:8080 \
    -e USER_NAME=gerrit \
    -e USER_EMAIL=<gerrit@your.site.domain> \
    -d openfrontier/gerrit

## Setup OAUTH options
    docker run \
    --name gerrit \
    -p 8080:8080 \
    -p 29418:29418 \
    -e AUTH_TYPE=OAUTH \
    -e OAUTH_ALLOW_EDIT_FULL_NAME=true \
    -e OAUTH_ALLOW_REGISTER_NEW_EMAIL=true \
    -e OAUTH_GOOGLE_RESTRICT_DOMAIN=your.site.domain> \
    -e OAUTH_GOOGLE_CLIENT_ID=1234567890 \
    -e OAUTH_GOOGLE_CLIENT_SECRET=dakjhsknksbvskewu-googlesecret \
    -e OAUTH_GOOGLE_LINK_OPENID=true \
    -e OAUTH_GITHUB_CLIENT_ID=abcdefg \
    -e OAUTH_GITHUB_CLIENT_SECRET=secret123 \
    -d openfrontier/gerrit

KNOWN ISSUE'S: The current OAUTH plugin is not up to date (2.11.3) test or compile the latest version from the website: https://github.com/davido/gerrit-oauth-provider

## Setup DEVELOPMENT_BECOME_ANY_ACCOUNT option
**DO NOT USE.** Only for use in a development environment.
When this is the configured authentication method a hyperlink titled Become appears in the top right corner of the page, taking the user to a form where they can enter the username of any existing user account, and immediately login as that account, without any authentication taking place. This form of authentication is only useful for the GWT hosted mode shell, where OpenID authentication redirects might be risky to the developer's host computer, and HTTP authentication is not possible.
    docker run \
    --name gerrit \
    -p 8080:8080 \
    -p 29418:29418 \
    -e AUTH_TYPE=DEVELOPMENT_BECOME_ANY_ACCOUNT \
    -d openfrontier/gerrit

## Sample operational scripts
   Sample scripts to create or destroy this Gerrit container are located at [openfrontier/gerrit-docker](https://github.com/openfrontier/gerrit-docker) project.

   A Jenkins docker image with some sample scripts to integrate with this Gerrit image can be found [here](https://registry.hub.docker.com/u/openfrontier/jenkins/).

   There's an [upper project](https://github.com/openfrontier/ci) which privdes sample scripts about how to use this image and a [Jenkins image](https://registry.hub.docker.com/u/openfrontier/jenkins/) to create a Gerrit-Jenkins integration environment.

## Sync timezone with the host server. 
   `docker run -d -p 8080:8080 -p 29418:29418 -v /etc/localtime:/etc/localtime:ro openfrontier/gerrit`

