# Gerrit Docker image
 Build a Docker image with the Gerrit code review system.
## Container Quickstart
1. Initialize and start gerrit.

 `$ docker run -d -p 8080:8080 -p 29418:29418 openfrontier/gerrit`

2. Open your browser to http://<dockerd host ip>:9000

## Start container with gerrit interactive installer.
1. Initialize and start gerrit.

 `$ docker run -it -p 8080:8080 -p 29418:29418 openfrontier/gerrit`

2. Open another console.

 `$ docker restart <container-name>`

## Use another container as the gerrit site storage.
1. Create a volume container.

 `$ docker run --name gerrit_volume openfrontier/gerrit echo "Gerrit volume container."`

2. Initialize and start gerrit using volume created above.

 `$ docker run -d --volumes-from gerrit_volume -p 8080:8080 -p 29418:29418 openfrontier/gerrit`

## Use local directory as the gerrit site storage.
1. Create a site directory for the gerrit site.

 `$ mkdir ~/gerrit_volume`

2. Initialize and start gerrit using the local directory created above.

 `$ docker run -d -v ~/gerrit_volume:/var/gerrit/review_site -p 8080:8080 -p 29418:29418 openfrontier/gerrit`

## Run dockerized gerrit with dockerized postgresql.

    #Start postgres docker
    docker run --name pg-gerrit -p 5432:5432 -e POSTGRES_USER=gerrit2 -e POSTGRES_PASSWORD=gerrit -e POSTGRES_DB=reviewdb -d postgres
    #Start gerrit docker
    docker run --name gerrit-site --link pg-gerrit:db -p 8080:8080 -p 29418:29418 WEBURL=http://your.site.url:8080 -e DATABASE_TYPE=postgresql -e AUTH_TYPE=LDAP -e LDAP_HOST=ldap-hostname -e LDAP_ACCOUNTBASE='ldap-basedn'  openfrontier/gerrit

## Sync timezone with the host server. 
 `$ docker run -d -p 8080:8080 -p 29418:29418 -v /etc/localtime:/etc/localtime:ro openfrontier/gerrit`

