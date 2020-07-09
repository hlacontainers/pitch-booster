#
# Copyright 2020 Tom van den Berg (TNO, The Netherlands).
# SPDX-License-Identifier: Apache-2.0
#

# Set default for build-time ARGs
ARG PITCH_BOOSTER_VERSION=skeleton

#########################
# Create Base image
#########################
FROM ubuntu:16.04 AS base

ARG PITCH_BOOSTER_VERSION

# Install required font-related packages for install4j
RUN apt-get update && apt-get install -y libfreetype6 libfontconfig

# Set BOOSTER_HOME
ENV BOOSTER_HOME=/usr/local/PitchBooster

#install Booster
COPY ./install_PitchBooster_v${PITCH_BOOSTER_VERSION}_linux_x64.sh /tmp/
RUN sh /tmp/install_PitchBooster_v${PITCH_BOOSTER_VERSION}_linux_x64.sh -q -d ${BOOSTER_HOME}

# Ensure there is a skeleton structure
RUN mkdir -p ${BOOSTER_HOME}

#########################
# Create Booster image
#########################
FROM ubuntu:16.04

RUN apt-get update && apt-get install -y net-tools dnsutils iproute2

# Set the BOOSTER_HOME
ENV BOOSTER_HOME=/usr/local/PitchBooster

# Copy the relevant items from base
COPY --from=base $BOOSTER_HOME $BOOSTER_HOME

# Set directory for start script and Booster config files
ENV CONFDIR /root

# Install start script
COPY ./start.sh ${CONFDIR}
COPY ./propdir ${CONFDIR}/propdir

# Set entrypoint
WORKDIR ${CONFDIR}
ENTRYPOINT ["/bin/sh", "./start.sh"]

# Export port between boosters
EXPOSE 8686/tcp

# Export port between application and booster
EXPOSE 8688/tcp

# Export port for ssh access to booster
EXPOSE 8623/tcp
