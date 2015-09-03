#!/bin/sh
#
# Script to automate the updating of the calling instance's 
#    Route53 DNS record. This script will only set a CNAME
#    pointing to the AWS-allocated public-hostname value
#
#################################################################

## Dynamic variables
METADATAURL="http://169.254.169.254/latest"
PUBLICHOSTNAME=$(curl -s ${METADATAURL}/meta-data/public-hostname/)
INSTANCEREGION=$(curl -s ${METADATAURL}/dynamic/instance-identity/document/ | \
                 awk -F":" '/region/{ print $2 }' | \
                 sed -e 's/"$//' -e 's/^.*"//')

## Static variables
PREFEREDNAME="<CNAME.F.Q.D.N>"
R53ZONEID="<Route53ZoneID>"
UPDATEFILE="/tmp/udate.json"

# Create the change-batch file
cat > ${UPDATEFILE} << EOF
{
  "Comment": "Update CNAME for this host",
  "Changes": [
    {
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "${PREFEREDNAME}",
        "Type": "CNAME",
        "TTL": 60,
        "ResourceRecords": [
          {
            "Value": "${PUBLICHOSTNAME}"
          }
        ]
      }
    }
  ]
}
EOF

# Request creation/update
aws --region ${INSTANCEREGION} route53 change-resource-record-sets \
    --hosted-zone-id "/hostedzone/${R53ZONEID}" \
    --change-batch file://${UPDATEFILE}

# Nuke the change-batch file
rm "${UPDATEFILE}"
