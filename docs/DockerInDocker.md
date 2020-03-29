# Instructions for running the Booster with Docker In Docker (DiD)

**Caveat: this is experimental.**

To work around the user defined MAC address restriction we will use Docker in Docker (DiD). The Booster image is turned into a volume that is mounted into the DiD container, but appears as a normal container to the  docker daemon running inside the DiD container. Here the container is attached to a Docker bridge network that supports user defined MAC addresses.

The steps to do this are shown below. Variations may be applied, such as injecting the license key into the Booster image, before turning it into a volume. The DiD setup can subsequently be used in Kubernetes.

## Prepare a DinD image with the Booster

Create and change to the directory ``booster-dind``
````
mkdir $HOME/booster-dind
cd $HOME/booster-dind
````

Create the following `.env` file (adapt values such as the MAC address):

````
REPOSITORY=hlacontainers/
PITCH_BOOSTER_VERSION=2_4_0L
MAC_ADDRESS=00:18:8B:0D:4F:2B
````

Start a DinD container and load a Booster container into the DinD. The container data is saved to `$HOME/booster-dind/var/lib/docker`.

````
# source the environment variables
source .env

# start a DiD container and mount /var/lib/docker
docker run --rm --privileged --name dind -p 22375:2375 -v $HOME/booster-dind/var/lib/docker:/var/lib/docker -d docker:dind dockerd -H tcp://0.0.0.0:2375

# load the Booster container into DiD so that data appears in /var/lib/docker
docker save ${REPOSITORY}pitch-booster:${PITCH_BOOSTER_VERSION} | docker -H :22375 load

# Stop DiD
docker stop dind
````

## Create data image with the Booster

At this point the image shows as data under the locally mounted `var/lib/docker` directory. There are a few steps to perform to create a volume from this data.

Change ownership of the ``var`` directory:

````
sudo chown -R $USER:$USER var
````

Remove any ``whiteout`` files since these cannot be copied and cause an error in the build. A whiteout file is an empty file with a special filename that signifies a path should be deleted. Whiteout files start with ``.wh.``.

````
find -name \.wh.'*' -delete
````

Also remove bock and character special files because these will cause a problem in building the image. Removal of these files seems unharmful.

````
find . -type c -delete
find . -type b -delete
````

Create the following `Dockerfile`:

````
FROM busybox
ENTRYPOINT [ "sh", "-c", " \
   if [ -n \"$VOLUME\" -a -n \"$1\" ]; then \
      if [ -n \"$OPTS\" ]; then \
         cp $OPTS $VOLUME $1; \
      else \
         cp -a $VOLUME $1; \
      fi; \
      echo \"Copied $VOLUME to $1\"; \
   fi" , \
"--" ]

ARG SRC
ARG VOLUMEDIR
ENV VOLUME ${VOLUMEDIR}/.
COPY ${SRC} ${VOLUMEDIR}/
VOLUME ${VOLUMEDIR}
````

The entrypoint is defined such that the contents of ``/var/lib/docker`` can optionally be copied to another directory upon start of this container. This feature is used when running this container under Kubernetes.

Create the following docker compose file:

````
version: '3'

services:
 image:
  build:
   context: .
   args:
    SRC: var/lib/docker
    VOLUMEDIR: /var/lib/docker
   dockerfile: Dockerfile
  image: ${REPOSITORY}pitch-booster-volume:${PITCH_BOOSTER_VERSION}
````

Build the volume. When we run `docker-compose build`,  Docker compose creates a tar ball of the build context to be sent to the engine. It does that in a temporary file. If  `/tmp` is too small we run out of disk space. If that is the case use another TMPDIR such as below:

````
TMPDIR=$(pwd) docker-compose build
````

## Run DiD with the Booster

Start data container:

````
docker run --name booster-volume ${REPOSITORY}pitch-booster-volume:${PITCH_BOOSTER_VERSION}
````

Run DiD with Booster:

````
docker run --rm --privileged \
	-p 22375:2375 -p 8989:8989 \
	--volumes-from booster-volume --name dind -d docker:dind dockerd -H tcp://0.0.0.0:2375
````

Test if the booster container image is present:

````
docker -H :22375 images
````

Stop and remove the containers:

````
docker stop dind booster-volume
docker rm booster-volume
````
And, finally, prune the Booster volume:

````
docker volume prune -f
````

