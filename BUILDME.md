# Build the Pitch Booster image

The Pitch Booster image can be built with the **Pitch RTI installer** from Pitch, or with the **skeleton installer** that is already present in this repository.

In the first case the Pitch RTI files are installed in the image and - when built - the image is ready to run.

In the second case only a skeleton directory structure and some necessary (but empty) files are created in the image. No Pitch files are installed in the image and the files from the Pitch Booster installer must be mounted into the Booster container afterwards in order to create a functional Booster container.

Both options are described below.

Tested Pitch Booster versions:

- `2_4_0`

## Build Booster image with the Pitch Booster installer

Perform the following steps to build the Pitch Booster image with the installer from Pitch.

### Obtain the Pitch Booster installer

This repository does not contain the Pitch Booster installer due to license restrictions. The first step is to obtain the installer and licenses from Pitch, see http://www.pitchtechnologies.com.

### Clone repository and drop in Pitch Booster installer

Clone this Git repository to the directory named `${WORKDIR}`.

Copy the Pitch Booster installer into the directory `${WORKDIR}/pitch-booster/docker/context`. The name of the Pitch Booster installer for Pitch Booster version `<version>` must match with `install_PitchBooster_v${PITCH_BOOSTER_VERSION}_linux_x64.sh`, for example `install_PitchBooster_v2_4_0_linux_x64.sh`.

Note the Pitch Booster version number in the file name, in this example `2_4_0`.

### Build image

Change into the directory `${WORKDIR}/pitch-booster/docker`.

Edit the file `.env` and set the Pitch Booster version number noted before.

Next, build the **complete** Booster container image with:

````
docker-compose -f build.yml build
````

The name of the resulting image is:

````
hlacontainers/pitch-booster:<version>
````

## Build skeleton Booster image with the skeleton installer

Perform the following steps to build a skeleton Pitch Booster image with the skeleton installer. Note again that the resulting image is not executable since the Pitch files are missing. These files need to be mounted in the container.

### Clone repository

Clone this Git repository to the directory named `${WORKDIR}`.

### Build image

Change into the directory `${WORKDIR}/pitch-booster/docker`.

Build the **skeleton** Booster container image with:

````
docker-compose -f build.yml build
````

The name of the resulting image is:

````
hlacontainers/pitch-booster:skeleton
````

