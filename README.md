![Build Status](https://img.shields.io/docker/cloud/build/hlacontainers/pitch-booster)
![Pulls](https://img.shields.io/docker/pulls/hlacontainers/pitch-booster)

# Pitch Booster image
This image is the containerized version of Pitch Booster, a product to support the creation of a virtual simulation network across different sites. The Pitch Booster container can be started in two modes:

- **parent mode**: the container runs a parent booster node, which connects to zero or more peer parent booster nodes, and has zero or more child booster nodes.
- **child mode**: the  container runs a child booster node, which connects to a single parent booster node.

Depending on the mode different environment variables should be set. In parent mode it is possible to specify the child booster nodes that may potentially connect to the parent booster node. It is also possible to specify additional peer (parent) booster nodes to which the parent booster node has to connect. In child mode the parent booster node must be specified.

This repository contains the files and instructions to build and run a Docker container image for Pitch Booster. **This repository does not include any Pitch files**. Pitch Booster and license keys must be acquired from the vendor. For more information about Pitch Booster, see http://pitchtechnologies.com.

For the instructions to build a skeleton or a complete Pitch Booster container image see [BUILDME](BUILDME.md).

## Container synopsis

`pitch-booster:<version> [-v] [-l <license key>] [-m <MAC address>] [-x]`

`-m`: Create a virtual network interface with the given MAC address. Requires that the container has `NET_ADMIN` capability. Overrides the `BOOSTER_MACADDRESS` environment variable.

`-v`: Provide verbose information.

`-l`: Run license activator with the given key, and exit.

`-x`: Exit after initialization, but before running the Booster. Overrides the `BOOSTER_EXIT` environment variable.

Ports:

`8686`: Listen port for remote boosters to connect.

`8688`: Listen port for federate applications to connect.

`8623`: Listen port for `ssh` access.

## Environment variables
### Any mode

| Option | Value                | default                        | Description                                                  | Required |
| ------ | -------------------- | ------------------------------ | ------------------------------------------------------------ | -------- |
| -e     | ``ISCHILD``          | not set                        | Determine mode; child mode if set, otherwise parent mode     | N        |
| -e     | `ADVERTISED_ADDRESS` | `containerip:internlistenport` | Set the booster internal advertised address; format is `hostname:port`, where port is the `INTERN_LISTENPORT`. | N        |
| -e     | `EXTERN_LISTENPORT`  | `8686`                         | Listen port for remote boosters on the external side of this booster. | N        |
| -e     | `INTERN_LISTENPORT`  | `8688`                         | Listen port for applications on the internal side of this booster. | N        |
| -e     | `PROPDIR`            | `./propdir`                    | Name of property directory containing  booster profiles.     | N        |
| -e     | `BOOSTER_LICENSE`    | not set                        | A booster license key.                                       | N        |
| -e     | `BOOSTER_MACADDRESS` | not set                        | The MAC address the license key is assigned to. Note that using this variable requires that the container has `NET_ADMIN` capabiity. | N |
| -e     | `BOOSTER_EXIT`       | not set                        | If set, Booster will exit once initialization has completed. | N        |

### Parent mode

| Option | Value              | default | Description                           | Required |
| ------ | ------------------ | ------- | ------------------------------------- | -------- |
| -e     | ``PARENTID``       |         | Booster parent identifier             | Y        |
| -e     | ``PARENTNAME``     |         | Booster parent name                   | Y        |
| -e     | `PARENTPROFILE`    | not set | Booster parent profile name           | N        |
| -e     | ``PEERID_<i>``     |         | Booster peer identifier (``i=1..m``)  | N        |
| -e     | ``PEERNAME_<i>``   |         | Booster peer name(``i=1..m``)         | N        |
| -e     | ``CHILDID_<j>``    |         | Booster child identifier (``j=1..n``) | N        |
| -e     | ``CHILDNAME_<j>``  |         | Booster child name (``j=1..n``)       | N        |
| -e     | `CHILDPROFILE_<j>` | not set | Booster child profile name (`j=1..n`) | N        |

### Child mode

| Option | Value             | default | Description                                          | Required |
| ------ | ----------------- | ------- | ---------------------------------------------------- | -------- |
| -e     | ``CHILDID``       |         | Booster child identifier                             | Y        |
| -e     | ``CHILDNAME``     |         | Booster child name                                   | Y        |
| -e     | `CHILDPROFILE`    | not set | Booster child profile name                           | N        |
| -e     | ``PARENTID``      |         | Booster parent identifier                            | Y        |
| -e     | ``PARENTNAME``    |         | Booster parent name                                  | Y        |
| -e     | ``PARENTADDRESS`` |         | Booster parent address (format is ``hostname:port``) | Y        |
| -e     | `PARENTPROFILE`   | not set | Booster parent profile name                          | N        |

## Booster profiles

In both modes (child, parent) it is possible to use the name of a profile instead of setting the Booster ID, NAME and ADRESSS explicitly via the environment variables. The name of the profile refers to a file `<profilename>.txt` that by default should be located under `$PROPDIR`. The profile file must contain the following name-value pairs:

````
ID=<Booster ID>
NAME=<Booster NAME>
ADDRESS=<Booster HOST>:<Booster EXTERN_LISTENPORT>
````

The address is only required for a parent booster.

## Run Pitch Booster with a license

Pitch Booster requires MAC address based license to run. This requires that the container is started with a specific MAC address and that the license key is either mounted into the container or already present (injected) inside the container image.

With the MAC address based license the Booster container must be started with the `--mac-address` option, providing a MAC address value that corresponds with the license key. Not all overlay networks support a user defined MAC address. Overlay networks under Docker generally support user defined MAC addresses, but overlay networks under Kubernetes do not. If the container is run in Kubernetes, a workaround based on environment variables exists. An earlier, experimental workaround to this limitation is described in [Run Booster with Docker In Docker](docs/DockerInDocker.md).

The following applies to overlay networks that support a user defined MAC address.

### Mount license key through environment variables

The Pitch Booster image takes the environment variables `BOOSTER_LICENSE` and `BOOSTER_MACADDRESS` as inputs. These can be used to mount a license into the container at run-time.

If the `BOOSTER_MACADDRESS` environment variable is set, the Booster container will create a virtual network interface with the given MAC address. This is useful for containers running in Kubernetes environments, where the MAC address of the main network interface can not be set explicitly. Note that the container requires the `NET_ADMIN` capability in order for this to work.

The `BOOSTER_LICENSE` environment variable can be used to insert a license string into the Booster container. The container will then attempt to activate this license. If the license is bound to a particular MAC addres, this MAC address should be added to the container through either the `--mac-address` option of Docker, or by setting the `BOOSTER_MACADDRESS` environment variable of the container.

Once the container has initialised a virtual network interface and/or attempted to activate a license key, it will continue to run normally.

### Mount license key

The license key can be mounted from the host file system or from a license container. The latter option provides more flexibility in running Booster since the license container can be deployed together with Booster without having to worry about host filesystem mounts. Several (one-off) steps need to be performed to create a license container image. The details can be found at [Create a Pitch License Container](docs/CreateLicenseImage.md).

### Inject license key

The license key can also be injected in the Booster container image, making it a permanent part of the image. The details can be found at [Inject a License into the Pitch Booster image](docs/InjectLicense.md).

With this option a new (licensed) Booster image is created. As a best practice the letter `L` is added to the version to indicate that the image holds a license key, for example:

````
hlacontainers/pitch-booster:2_4_0L
````

## SSH access

Once a booster is running with the SSH port exposed, it is possible to connect to the booster via SSH (see the Pitch Booster manual for the available commands). Use admin/admin for username and password.

For example, connect with:

```
ssh -p 8623 admin@your_booster_address
```

Replacing `your_booster_address` by the address of the booster.
