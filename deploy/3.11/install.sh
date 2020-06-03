#!/bin/bash

oc adm new-project super-project-operator

oc process -f install-template-3.11-private.yaml --local  \
    -p GIT_REPO=$1  \
    -p GIT_CLONE_SECRET=$2  \
    -p GIT_BRANCH=$3  | oc -n super-project-operator  apply -f-






