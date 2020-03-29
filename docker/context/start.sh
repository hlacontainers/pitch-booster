#!/bin/sh

#
# Copyright 2020 Tom van den Berg (TNO, The Netherlands).
# SPDX-License-Identifier: Apache-2.0
#

# Start script for Booster

getProperty() {
   PROP_KEY=$1
   PROP_FILE=$2
   PROP_VALUE=`cat $PROP_FILE | grep "$PROP_KEY" | sed 's/\r$//'| cut -d'=' -f2`
   echo $PROP_VALUE
}

# Initialize variables
verbose=0
license=""

boosterconfig=$CONFDIR/booster.conf
glbconfig=$CONFDIR/glb.conf
cblconfig=$CONFDIR/cbl.conf

# Set defaults
X=${EXTERN_LISTENPORT:=8686}
X=${INTERN_LISTENPORT:=8688}
X=${PROPDIR:=./propdir}

# Bridge submode is an undocumented settig to make booster work as a containter.
# All data communication on the internal side of the booster runs via the booster.
X=${ISBRIDGED:=1}

HOSTNAME=`hostname`

# Set default advertised address to the container address
X=${ADVERTISED_ADDRESS:="$(hostname -i):$INTERN_LISTENPORT"}

echo "ISCHILD="$ISCHILD

echo "PARENTID="$PARENTID
echo "PARENTNAME"=$PARENTNAME
echo "PARENTADDRESS"=$PARENTADDRESS
echo "PARENTPROFILE"=$PARENTPROFILE

echo "CHILDID"=$CHILDID
echo "CHILDNAME"=$CHILDNAME
echo "CHILDPROFILE"=$CHILDPROFILE

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

while getopts "vl:" opt; do
    case "$opt" in
	v)	verbose=1
		;;
	l)	license=$OPTARG
		;;
	esac
done

# shift away processed options
shift $((OPTIND-1))
[ "$1" = "--" ] && shift

if [ "$license" != "" ]; then
	echo "Booster: run license activator with '$license'"
	echo $license | /usr/local/PitchBooster/BoosterLicenseActivator
	exit
fi

if [ -z "${ISCHILD}" ] || [ "${ISCHILD}" = "0" ]; then
	# Create parent booster
	echo "This is a parent booster"

	if [ -n "${PARENTPROFILE}" ] && [ -f "${PROPDIR}/${PARENTPROFILE}.txt" ]; then
		echo "Using parent profile: "${PROPDIR}/${PARENTPROFILE}.txt
	
		# get info from profile
		PARENTID=$(getProperty "ID" ${PROPDIR}/${PARENTPROFILE}.txt)
		PARENTNAME=$(getProperty "NAME" ${PROPDIR}/${PARENTPROFILE}.txt)
	fi

	if [ -z "${PARENTID}" ] || [ -z "${PARENTNAME}" ]; then
		echo "Parent ID or NAME not set"
		exit
	fi
	
	# Create booster config
	echo "" > $boosterconfig

	echo "Booster {" >> $boosterconfig
	echo "    Id=\"${PARENTID}\"" >> $boosterconfig
	echo "}" >> $boosterconfig
	echo "Ext {" >> $boosterconfig
	echo "    IP {" >> $boosterconfig
	echo "        addr=all" >> $boosterconfig
	echo "        port=${EXTERN_LISTENPORT}" >> $boosterconfig
	echo "    }" >> $boosterconfig
	echo "}" >> $boosterconfig
	echo "Int {" >> $boosterconfig
	
	if [ -n "${ADVERTISED_ADDRESS}" ]; then
		echo "    advertisedAddress=\"${ADVERTISED_ADDRESS}\"" >> $boosterconfig
	fi
	
	# determine bridged submode
	if [ -z "${ISBRIDGED}" ] || [ "${ISBRIDGED}" = "0" ] ; then
		echo "Parent booster: NOT in bridged submode"
	else
		echo "Parent booster: in bridged submode"
		echo "    bridgedMode=true" >> $boosterconfig
	fi

	echo "    IP {" >> $boosterconfig
	echo "        addr=all" >> $boosterconfig
	echo "        port=${INTERN_LISTENPORT}" >> $boosterconfig
	echo "    }" >> $boosterconfig
	echo "}" >> $boosterconfig
	echo "Name=\"${PARENTNAME}\"" >> $boosterconfig
	echo "isChild=\"false\"" >> $boosterconfig
	
	# Create global booster list
	echo "Boosters {" > $glbconfig
	echo "  \"${PARENTNAME}\" {" >> $glbconfig
    echo "    address=\"${HOSTNAME}:${EXTERN_LISTENPORT}\"" >> $glbconfig
	echo "    id=\"${PARENTID}\"" >> $glbconfig
	echo "  }" >> $glbconfig

	n=1
	peeridxx="PEERID_"$n
    peerid=$(eval "echo \$${peeridxx}")
	peernamexx="PEERNAME_"$n
    peername=$(eval "echo \$${peernamexx}")
	
	while [ -n "${peerid}" ] && [ -n "${peername}" ]; do
		echo "  \"${peername}\" {" >> $glbconfig
		echo "    id=\"${peerid}\"" >> $glbconfig
		echo "  }" >> $glbconfig

		n=$((n+1))
		peeridxx="PEERID_"$n
		peerid=$(eval "echo \$${peeridxx}")
		peernamexx="PEERNAME_"$n
		peername=$(eval "echo \$${peernamexx}")
	done	

	echo "}" >> $glbconfig
	echo "Name=\"Global booster list\"" >> $glbconfig
	
	# Create child booster list
	echo "Boosters {" > $cblconfig

	n=1
	childidxx="CHILDID_"$n
    childid=$(eval "echo \$${childidxx}")
	childnamexx="CHILDNAME_"$n
    childname=$(eval "echo \$${childnamexx}")
	
	while [ -n "${childid}" ] && [ -n "${childname}" ]; do
		echo "  \"${childname}\" {" >> $cblconfig
		echo "    id=\"${childid}\"" >> $cblconfig
		echo "  }" >> $cblconfig

		n=$((n+1))
		childidxx="CHILDID_"$n
		childid=$(eval "echo \$${childidxx}")
		childnamexx="CHILDNAME_"$n
		childname=$(eval "echo \$${childnamexx}")
	done
	
	n=1
	childprofilexx="CHILDPROFILE_"$n
    chilprofile=$(eval "echo \$${childprofilexx}")

	while [ -f "${PROPDIR}/${chilprofile}.txt" ]; do
		echo "Using child profile: "${PROPDIR}/${chilprofile}.txt

		# get info from profile
		childid=$(getProperty "ID" ${PROPDIR}/${chilprofile}.txt)
		childname=$(getProperty "NAME" ${PROPDIR}/${chilprofile}.txt)		
		
		if [ -z "${childid}" ] || [ -z "${childname}" ]; then
			break
		fi
		
		echo "  \"${childname}\" {" >> $cblconfig
		echo "    id=\"${childid}\"" >> $cblconfig
		echo "  }" >> $cblconfig

		n=$((n+1))
		childprofilexx="CHILDPROFILE_"$n
		chilprofile=$(eval "echo \$${childprofilexx}")
	done
	
	echo "}" >> $cblconfig
	echo "Name=\"Child booster list\"" >> $cblconfig
else
	# create child booster
	echo "This is a child booster"

	if [ -n "${CHILDPROFILE}" ] && [ -f "${PROPDIR}/${CHILDPROFILE}.txt" ]; then
		echo "Using child profile: "${PROPDIR}/${CHILDPROFILE}.txt

		# get info from profile
		CHILDID=$(getProperty "ID" ${PROPDIR}/${CHILDPROFILE}.txt)
		CHILDNAME=$(getProperty "NAME" ${PROPDIR}/${CHILDPROFILE}.txt)
	fi

	if [ -n "$PARENTPROFILE" ] && [ -f "${PROPDIR}/${PARENTPROFILE}.txt" ]; then
		echo "Using parent profile: "${PROPDIR}/${PARENTPROFILE}.txt

		# get info from profile
		PARENTID=$(getProperty "ID" ${PROPDIR}/${PARENTPROFILE}.txt)
		PARENTNAME=$(getProperty "NAME" ${PROPDIR}/${PARENTPROFILE}.txt)
		PARENTADDRESS=$(getProperty "ADDRESS" ${PROPDIR}/${PARENTPROFILE}.txt)
		if [ -n "${PARENTADDRESS}" ]; then
			PARENTADDRESS=${PARENTADDRESS}
		else
			PARENTADDRESS=""
		fi
	fi
	
	if [ -z "${CHILDID}" ] || [ -z "${CHILDNAME}" ]; then
		echo "Child ID or NAME not set"
		exit
	fi
	if [ -z "${PARENTID}" ] || [ -z "${PARENTNAME}" ] || [ -z "${PARENTADDRESS}" ]; then
		echo "Parent ID, NAME or ADDRESS not set"
		exit
	fi

	# Create booster config
	echo "Booster {" > $boosterconfig
	echo "    Id=\"${CHILDID}\"" >> $boosterconfig
	echo "}" >> $boosterconfig
	echo "Ext {" >> $boosterconfig
	echo "    IP {" >> $boosterconfig
	echo "        addr=all" >> $boosterconfig
	echo "        port=0" >> $boosterconfig
	echo "    }" >> $boosterconfig
	echo "}" >> $boosterconfig
	echo "Int {" >> $boosterconfig

	if [ -n "${ADVERTISED_ADDRESS}" ]; then
		echo "    advertisedAddress=\"${ADVERTISED_ADDRESS}\"" >> $boosterconfig
	fi
	
	# determine bridged submode
	if [ -z "${ISBRIDGED}" ] || [ "${ISBRIDGED}" = "0" ] ; then
		echo "Child booster: NOT in bridged submode"
	else
		echo "Child booster: in bridged submode"
		echo "    bridgedMode=true" >> $boosterconfig
	fi
	
	echo "    IP {" >> $boosterconfig
	echo "        addr=all" >> $boosterconfig
	echo "        port=${INTERN_LISTENPORT}" >> $boosterconfig
	echo "    }" >> $boosterconfig
	echo "}" >> $boosterconfig
	echo "Name=\"${CHILDNAME}\"" >> $boosterconfig
	echo "isChild=\"true\"" >> $boosterconfig

	# Create global booster list
	echo "Boosters {" > $glbconfig

	echo "  \"${PARENTNAME}\" {" >> $glbconfig
    echo "    address=\"${PARENTADDRESS}\"" >> $glbconfig
	echo "    id=\"${PARENTID}\"" >> $glbconfig
	echo "  }" >> $glbconfig

	echo "  \"${CHILDNAME}\" {" >> $glbconfig
    echo "    address=\"indirect:0\"" >> $glbconfig
	echo "    id=\"${CHILDID}\"" >> $glbconfig
	echo "  }" >> $glbconfig
	
	echo "}" >> $glbconfig
	echo "Name=\"Child booster list\"" >> $glbconfig
fi

if [ $verbose -eq 1 ]; then
	if [ -z "${ISCHILD}" ] || [ "${ISCHILD}" = "0" ]; then
		echo "=================="
		echo "PARENT CONFIG"
		echo "=================="
		cat $boosterconfig
		echo "=================="
		echo "GLOBAL BOOSTERLIST"
		echo "=================="
		cat $glbconfig
		echo "=================="
		echo "CHILD BOOSTERLIST"
		echo "=================="
		cat $cblconfig
		echo "=================="
	else
		echo "=================="
		echo "CHILD CONFIG"
		echo "=================="
		cat $boosterconfig
		echo "=================="
		echo "GLOBAL BOOSTERLIST"
		echo "=================="
		cat $glbconfig
		echo "=================="
	fi
fi

# Start process
echo "Booster: start"

if [ -z "${ISCHILD}" ] || [ "${ISCHILD}" = "0" ]; then
	/bin/sh /usr/local/PitchBooster/PitchBooster $boosterconfig --gbl $glbconfig --cbl $cblconfig
else
	/bin/sh /usr/local/PitchBooster/PitchBooster $boosterconfig --gbl $glbconfig	
fi
