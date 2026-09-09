# Setup

## 1. Docker Network

Make sure the `homelab` Docker network exists:

```sh
docker network create homelab
```

## 2. AWS IAM User (Route 53 DNS Challenge)

Caddy uses the Route 53 DNS provider to automate Let's Encrypt certificate renewal.

Create an IAM user in AWS with the following policy (replace `<HOSTED_ZONE_ID>` with your actual Route 53 hosted zone ID):

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "route53:ListHostedZonesByName",
                "route53:ListHostedZones"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "route53:ListResourceRecordSets",
            "Resource": "arn:aws:route53:::hostedzone/<HOSTED_ZONE_ID>"
        },
        {
            "Effect": "Allow",
            "Action": "route53:GetChange",
            "Resource": "arn:aws:route53:::change/*"
        },
        {
            "Effect": "Allow",
            "Action": "route53:ChangeResourceRecordSets",
            "Condition": {
                "ForAllValues:StringEquals": {
                    "route53:ChangeResourceRecordSetsRecordTypes": "TXT"
                },
                "ForAllValues:StringLike": {
                    "route53:ChangeResourceRecordSetsNormalizedRecordNames": "_acme-challenge.*"
                }
            },
            "Resource": "arn:aws:route53:::hostedzone/<HOSTED_ZONE_ID>"
        }
    ]
}
```

Generate an access key for the IAM user abd add it to `.env` in the next step.

> **Note:** Route 53 is a global service, but the AWS SDK requires a region for request signing. `us-east-1` is the conventional choice.

# Installation

1. Copy `.env.example` to `.env`:
1. Edit `.env` and set your domains and AWS credentials:
1. Bring up the containers: `docker compose up -d`

> **Note:** DNS-01 challenges can intermittently fail due to DNS propagation
> delays (Let's Encrypt checks the TXT record before it has fully propagated).
> If you see `No TXT record found` errors, restarting the container is usually
> enough — Caddy will retry the challenge automatically.
