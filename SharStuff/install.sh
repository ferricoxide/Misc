#!/bin/sh
#
# Self-extracting archive script-stub
# To use:
# 1. Populate a directory with installable components and an install.sh
#    script that handles installation of those components
# 2. Change into the populated directory
# 3. Create a gzip-compressed tar-archive of the directory by executing
#    something similar to `tar pczvf ../myarc.tgs .`
# 4. Append the tar-archive to this script by executing something similar
#    to `cat /PATH/TO/TAR-ARCHIVE >> /PATH/TO/THIS-SCRIPT
#
#################################################################
DELIMIT="__STREAM_BEGIN__"
STARTDIR=$(readlink -f $(dirname $0))

# Where pre-install modules will be staged
function CreateStage() {
   echo "Attempting to create install-staging directory..."
   STAGEDIR=$(mktemp -d /tmp/Install.XXXXXX)
   
   if [ "${STAGEDIR}" = "" ]
   then
      echo "Failed to create staging-directory. Aborting..." > /dev/stderr
      exit 1
   else
      echo "Will stage working files to ${STAGEDIR}"
   fi
}

# Decompose this SHAR to grab the binary-stream and stage its contents
function GankStream() {
   echo "Attempting to extract payload to install-staging directory..."
   # In case calling-shell's umask is too restrictive
   umask 022

   # Read the script-ending binary stream and de-archive
   sed '1,/^'${DELIMIT}'$/d' "${0}" | tar xzvf - -C ${STAGEDIR}
}

# Install it all...
function InstallIt() {
   echo "Attempting to run payload's installer-script"
   cd ${STAGEDIR}
   ${STAGEDIR}/install.sh
   cd ${STARTDIR}
}

# Nuke out the pre-install content
function NukeIt() {
   echo "Attempting to clean-up staging directory..."
   rm -rf ${STAGEDIR}
   if [[ $? -eq 0 ]]
   then
      echo "Successfully deleted ${STAGEDIR}"
   else
      echo "Failed to delete ${STAGEDIR}" > /dev/stderr
   fi
}


###############
# Main-run...
###############
CreateStage
GankStream
InstallIt
NukeIt

# Do this to ensure no attempt to execute binary-payload
exit 0

# Binary-payload tacked on after delimiter-string
__STREAM_BEGIN__
