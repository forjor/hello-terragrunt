#!/bin/bash

# This script should only prompt a user the first time.
if [ -f terraform.tfvars ]; then
    echo -e "\n\n\n******************************************************************************************"
    echo "This example is being driven with terraform.tfavrs with the content:"
    cat terraform.tfvars
    echo -e "******************************************************************************************\n\n\n"
    exit 0
fi

echo -e "\n\n\n******************************************************************************************"
echo "This prompt will determine which domain to base the example on. A subdomain will be created from this root."
echo "The AWS CLI will scan for the first available hosted zone and the script will offer that domain, or allow you to serlect another."
echo -e "******************************************************************************************\n\n\n"

aws sts get-caller-identity > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "Please log in with the AWS CLI."
    exit 1
fi

aws route53 list-hosted-zones --query 'HostedZones[0].Name' --output text > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "No hosted zones found. Assigning root_domain_name = \"\" in terraform.tfvars"
    echo "root_domain_name = \"\"" > terraform.tfvars
    exit 0
fi

export FIRST_HOSTED_ZONE_WITH_DOT_SUFFIX=$(aws route53 list-hosted-zones --query 'HostedZones[0].Name' --output text)
export ROOT_DOMAIN_NAME="${FIRST_HOSTED_ZONE_WITH_DOT_SUFFIX%.}"

echo "Found $ROOT_DOMAIN_NAME as a possible root. Enter Y to select this domain, enter N to choose not to use a domain, or enter a specific domain literally to choose it instead."
read -p "Enter [Y/N/ROOT_DOMAIN_NAME]: " SELECTION

if [ "$SELECTION" == "Y" ]; then
    echo -e "\n\nAssigning root_domain_name = \"$ROOT_DOMAIN_NAME\" in terraform.tfvars\n\n\n"
    echo "root_domain_name = \"$ROOT_DOMAIN_NAME\"" > terraform.tfvars
    exit 0
elif [ "$SELECTION" == "N" ]; then
    echo -e "\n\nAssigning root_domain_name = \"\" in terraform.tfvars\n\n\n"
    echo "root_domain_name = \"\"" > terraform.tfvars
    exit 0
else
    echo -e "\n\nAssigning root_domain_name = \"$SELECTION\" in terraform.tfvars\n\n\n"
    echo "root_domain_name = \"$SELECTION\"" > terraform.tfvars
    exit 0
fi
