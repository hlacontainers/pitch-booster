# Create a Pitch Booster license container

Pitch Booster requires a license key in order to run. The license file with the license key and the associated MAC address must be requested from Pitch.

The steps below describe how to create a Pitch Booster license container with the license key in it, and how to run Pitch Booster with the Pitch license container. The creation of the license container image only has to be done once.

## Create build directory and environment settings file

Prepare a `builddir` with a `.env` file in it:

````Ada
mkdir builddir

cd builddir

# Change the following environment values to match your license key:
cat << EOF >> .env
REPOSITORY=hlacontainers/
PITCH_BOOSTER_VERSION=2_4_0
LICENSE_IMAGE=booster-license
MAC_ADDRESS=00:18:8B:0D:4F:2B
EOF
````

The value for the MAC address above is an example. Adapt the value of `MAC_ADDRESS` to a value that matches with the license key.

## Set LICENSE environment variable

Copy the license file to the build directory and rename the file to `LicenseFile.txt`.

From a Linux shell execute the following command:

```
LICENSE=$(sed -n 2p LicenseFile.txt)
```

This command sets the environment variable `LICENSE` to the second line in the license file.

## Run license activator

Next, run the license activator to create a license key file from this value, using the following command from a Linux shell:

```
source .env

docker run \
  --mac-address=${MAC_ADDRESS} \
  --rm -v $PWD:/usr/local/PitchBooster/jre/.systemPrefs/se/pitch/booster/config \
  ${REPOSITORY}pitch-booster:${PITCH_BOOSTER_VERSION} -l ${LICENSE} -x
```

After running this command a file `prefs.xml` should be created in the current working directory.

## Create license container image

In this step a license container image is built with the license key file in it. We use `docker-compose` to create the license container image.

Create the following two files in the `builddir`:

The file `docker-compose.yml`:

```
version: '3'

services:
 license:
  build:
   context: .
   args:
    SRC: prefs.xml
    VOLUMEDIR: /data
   dockerfile: Dockerfile
  image: ${LICENSE_IMAGE}
```

And the file `Dockerfile`:

```
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
```

The script defined for `ENTRYPOINT` is used to optionally initialize a volume with the data from the license container. When the container is run with an argument, the data in the container is copied by the script to the provided directory location. Docker does this automatically by declaring a `VOLUME` and there is no need for such a script, however under Kubernetes this must be done explicitly through the entry point script.

And lastly build the license container image with the following command:

````
docker-compose build
````

## Update the license data

In case the license container is updated with new license data, the license volume needs to be removed from the host filesystem so that the new data can be copied to the host filesystem. To remove the license volume from the host filesystem, make sure that no container that mounts the volume exists (either running or stopped). You can verify this with the command `docker ps -a`. If no container mounts the data volume anymore, then use the command `docker volume prune` to remove the license volume.

