Inject a License into the Pitch Booster Image
=====================================

By injecting the license key into the image itself, the license becomes part of the Pitch Booster image. There is no need to refer to a license server or use a license container.

To do this, perform the following steps.

## Create build directory and environment settings file

Prepare a `builddir` with a `.env` file in it:

````Ada
mkdir builddir

cd builddir

# Change the following environment values to match your license key:
cat << EOF >> .env
REPOSITORY=hlacontainers/
PITCH_BOOSTER_VERSION=2_4_0
MAC_ADDRESS=00:18:8B:0D:4F:2B
EOF
````

The value for the MAC address above is an example. Adapt the value of `MAC_ADDRESS` to a value that matches with the license key.

Inject license and create new image
----------------------

Copy the license file to the build directory and rename the file to `LicenseFile.txt`.

Execute the following commands from a shell. Note that a new image is committed with `docker commit` and tagged with the additional letter `L` to indicate that this image includes a license key.

```
# source the environment variables
source .env

# inject license
docker run \
	--mac-address=${MAC_ADDRESS} \
	--name booster \
	${REPOSITORY}pitch-booster:${PITCH_BOOSTER_VERSION} -l $(sed -n 2p LicenseFile.txt)

# commit as a new image
docker commit -c 'ENTRYPOINT ["/bin/sh", "./start.sh"]' booster ${REPOSITORY}pitch-booster:${PITCH_BOOSTER_VERSION}L

# clean up
docker rm booster
```

