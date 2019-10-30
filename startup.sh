#!/bin/bash

GCLOUD='/google-cloud-sdk/bin/gcloud'
KUBECTL='/usr/local/bin/kubectl'

# Decode key
echo $BASE64_KEY | base64 -d - > /gcloud.json

# Set project
PROJECT=`cat /gcloud.json | jq -r .project_id`
if [[ $DEBUG == "True" ]]
then
    $GCLOUD config set project $PROJECT
else
    $GCLOUD config set project $PROJECT > /dev/null 2>&1
fi

if [[ $? == 0 ]]
then
    echo "Project set to : $PROJECT"
else
    echo "Unable to set project: $PROJECT"
    exit 1
fi

# Auth with JSON key
if [[ $DEBUG == "True" ]]
then
    $GCLOUD auth activate-service-account --key-file /gcloud.json 
else
    $GCLOUD auth activate-service-account --key-file /gcloud.json > /dev/null 2>&1
fi
if [[ $? == 0 ]]
then
    echo "JSON auth : Success"
else
    echo "Unable to auth"
    exit 1 
fi

# Create kubectl config if needed
if [[ $KUBECTL == "True" ]]
then
    if [ -z $CLUSTER ] 
    then
        echo "CLUSTER variable required for kubectl"
        exit 1
    fi
    if [ -z $ZONE ] 
    then
        echo "ZONE variable required for kubectl"
        exit 1
    fi
    if [[ $DEBUG == "True" ]]
    then
        $GCLOUD container clusters get-credentials $CLUSTER --zone $ZONE
    else
        $GCLOUD container clusters get-credentials $CLUSTER --zone $ZONE > /dev/null 2>&1
    fi
    if [[ $? == 0 ]]
    then
        echo "kubectl config : Success"
    else
        echo "Unable to create config"
        exit 1 
    fi
fi

# Execute script if specified
if [ -n "$SCRIPT_FILE" ]
then
    curl $SCRIPT_FILE -o /execute_me -s
    chmod +x /execute_me
    /execute_me
fi

# Execute commands if specified
if [ -n "$SCRIPT" ]
then
    IFS=","
    for v in $SCRIPT
    do
        eval "$v"
    done
fi
