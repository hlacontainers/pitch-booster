#!/bin/sh

# This script creates a docker data volume image for Booster

# Set docker image name and tag
export IMAGE=app-docker136.hex.tno.nl/pitch/booster
export TAG=2.3.1a

rm -rf var

docker run --rm --privileged --name dind -p 22375:2375 -v $(pwd)/var/lib/docker:/var/lib/docker -d docker:stable-dind

down=1
while [ $down -ne 0 ]; do
        echo "Wait for dind at localhost:22375"

        # Check if the port is open; use the -z option to just scan and not connect
        down=`nc -z localhost 22375 < /dev/null > /dev/null; echo $?`

        # Sleep for the next attempt
        sleep 1
done
echo "localhost:22375 is up"

docker save $IMAGE:$TAG | docker -H :22375 load
docker stop dind

sudo chown -R $USER:$USER var
find -name \.wh.'*' -delete

TMPDIR=$(pwd) docker-compose build

docker push $IMAGE-volume:$TAG
