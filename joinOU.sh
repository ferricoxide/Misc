#!/bin/sh
#
# Tool to join a Linux-based system to a specific container within and
# Active Directory domain.
#
# This script currently supports use with the third-party AD-integration
# tools Centrify and LikeWise/PowerBroker
#
# Use of this script requires the availability of:
# * The nslookup utility
# * The ldapsearch utility
#
# Use of this script further requires
# * that the AD client-system have its hostname properly set to FQDN
# * The domain name service contains appropriate AD-related 'srv' records
# * That an appropriate tenant OU structure be ready within the target
#   Active Directory domain
#
# To localize for use in your environment
# * Set JOINACCT value to name of service account used for joining
#   client systems to the Active Directory domain
# * Set JOINPASS to the password string used to authenticate the
#   JOINACCT service account to the domain
# * Set OUROOTDN to an appropriate DN within the AD domain (may be
#   set to the domain-root or a sub-section of the domain)
#
###########################################################################

# Script Arguments
TENANT=${1:-UNDEF}
DOMAINNAME=${2:-`hostname -d`}

# Standard variables and argument-transforms
SHORTDOM=`echo ${DOMAINNAME} | sed 's/\..*$//' | tr "[:lower:]" "[:upper:]"`
JOINACCT="##SERVICEACCOUNTNAME##"
JOINPASS="##SERVICEACCOUNTPASSWORD##"
OUROOTDN="##AD_LDAP_ROOT##"

# Ensure that DNS contains service-records
ValidDomain() {
   DNSCHK="/usr/bin/nslookup"
   DNSARG="-type=srv"

   if [ -x ${DNSCHK} ]
   then
      SRVREC="_ldap._tcp.${DOMAINNAME}"
      ${DNSCHK} ${DNSARG} ${SRVREC} | grep NXDOMAIN > /dev/null 2>&1
      if [ $? -eq 0 ]
      then
         echo "No LDAP service record found. Aborting..."
	 exit 1
      else
         DOMSERV=`${DNSCHK} ${DNSARG} ${SRVREC} | \
	    awk '/service/{print $7}' | head -1`
      fi
   else
      echo "${DNSCHK} not present. Cannot look up OU-path. Aborting..."
      exit 1
   fi
}

# Compute OU-path from tenant-name
GetOUpath() {
   LDAPCHK="/usr/bin/ldapsearch"
   if [ -x ${LDAPCHK} ]
   then
      OUPATH=`${LDAPCHK} -LLL -r -h ${DOMSERV} -w "${JOINPASS} -xD \
        "${JOINACCT}@${DOMAINNAME}" -b "${OUROOTDN}" -s sub ou=${TENANT} dn | \
        grep ^dn: | sed -e 's/^dn: //'`
   else
      echo "Cannot do OU path-fetch. Aborting..."
      exit 1
   fi
}

# Do AD operation based on type of AD tools present
CheckADtool() {
  HAVECENTRIFY=$(rpm --quiet -q CentrifyDC)$?
  HAVELIKEWISE=$(rpm --quiet -q likewise-open)$?
  HAVEPOWBROKR=$(rpm --quiet -q pbis-open)$?

  if [ ${HAVELIKEWISE} -eq 0 ] || [ ${HAVEPOWBROKR} -eq 0 ]
  then
     JOINOPTS="--assumeDefaultDomain yes --userDomainPrefix ${SHORTDOM}"
     JOINCMD="/opt/likewise/bin/domainjoin-cli"

     ${JOINCMD} join ${JOINOPTS} --ou "ou=${TENANT}-Servers,${OUPATH}" \
       ${DOMAINNAME} ${JOINACCT} ${JOINPASS}"
  elif [ ${HAVECENTRIFY} -eq 0 ]
  then
     CENTRIFYCFG="/etc/centrifydc/centrifydc.conf"
     JOINCMD="/usr/share/centrifydc/libexec/adjoin"

     ${JOINCMD} -w -u ${JOINACCT} -p ${JOINPASS} -c \
       "ou=${TENANT}-Servers,${OUPATH}" ${DOMAINNAME}
     mv ${CENTRIFYCFG} ${CENTRIFYCFG}-BAK && echo \
     "auto.schema.homedir: /home/${SHORTDOM}/%{user}" > ${CENTRIFYCFG}
  fi
}

# Abort if no tenant set
if [ "${TENANT}" = "UNDEF" ]
then
   echo "No tenant-name set. Aborting..."
   exit 2
fi

ValidDomain

GetOUpath

CheckADtool
