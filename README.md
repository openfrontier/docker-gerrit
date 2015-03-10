# Gerrit Docker image
 Build a Docker image with the Gerrit code review system.
## Container Quickstart
1. Initialize and start gerrit.

 `$ docker run -d -p 8080:8080 -p 29418:29418 openfrontier/gerrit`

2. Open your browser to http://<dockerd host ip>:9000

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

## Stop/restart gerrit service within the container.
 `$ docker exec $gerrit-container-name  /var/gerrit/review_site/bin/gerrit.sh stop`
 `$ docker exec $gerrit-container-name  /var/gerrit/review_site/bin/gerrit.sh start`
 `$ docker exec $gerrit-container-name  /var/gerrit/review_site/bin/gerrit.sh restart`

## Sync timezone with the host server. 
 `$ docker run -d -p 8080:8080 -p 29418:29418 -v /etc/localtime:/etc/localtime:ro openfrontier/gerrit`

