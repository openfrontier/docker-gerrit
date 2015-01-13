# docker-gerrit
 Build a Docker image with the Gerrit code review system
## User guide
1. Create a volume container.

 `$ docker run --name gerrit_volume openfrontier/gerrit echo "Gerrit volume container."`

2. Initialize and start gerrit using volume created before.

 `$ docker run --volumes-from gerrit_volume -p 8080:8080 -p 29418:29418 gerrit`
 
