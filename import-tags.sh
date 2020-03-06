#!/bin/bash
aws_region=$(/usr/bin/curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -c -r .region)

get_instance_tags () {
    instance_id=$(/usr/bin/curl --silent http://169.254.169.254/latest/meta-data/instance-id)
    echo $(/usr/bin/aws ec2 describe-tags --filters "Name=resource-id,Values=$instance_id" --region $aws_region)
}

get_ami_tags () {
    ami_id=$(/usr/bin/curl --silent http://169.254.169.254/latest/meta-data/ami-id)
    echo $(/usr/bin/aws ec2 describe-tags --filters "Name=resource-id,Values=$ami_id" --region $aws_region)
}

tags_to_env () {
    tags=$1

    for key in $(echo $tags | /usr/bin/jq -r ".[][].Key"); do
        value=$(echo $tags | /usr/bin/jq -r ".[][] | select(.Key==\"$key\") | .Value")
        key=$(echo $key | /usr/bin/tr '-' '_' | /usr/bin/tr '[:lower:]' '[:upper:]')
        echo $key=$value
        export $key="$value"
    done
}

ami_tags=$(get_ami_tags)
instance_tags=$(get_instance_tags)

tags_to_env "$ami_tags"
tags_to_env "$instance_tags"
export AWS_REGION="$aws_region"
