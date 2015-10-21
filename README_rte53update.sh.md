This script is used to automate the updating of the calling instance's Route53 DNS record. As written, this script will only set a CNAME pointing to the AWS-allocated public-hostname value.

Dependencies:
It is recommended to set up a Route53 security-policy and and assign it to a role. The role should have the following Route53 Permissions set:

- route53:ChangeResourceRecordSets
- route53:GetHostedZone
- route53:ListResourceRecordSets

This role can then be assigned to an instance or to a service account. If using a service account, it will be necessary to populate the script's `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` variables with the IAM user's associated ID/Key values.

The FQDN that will be placed into Route53 comes from the value set in the script's `PREFEREDNAME` variable.

Set the value of `R53ZONEID` to the Route53 zone ID of the DNS zone to be updated. It's expected that this script will only be used for updating public DNS zones. The logic around zone updates may be updated if requests for such an enhancement are submitted via the git service's "issues" system.

Assuming that the instance-role or service-account has adequate permissions, a DNS CNAME record with a 60-second time to live will be created in the target zone. The update-action will be logged to STDOUT and copied to the host systems logging-service. Events in the system log will be tagged `rte53update`.
