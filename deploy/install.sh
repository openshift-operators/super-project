#!/bin/bash

oc process -f deploy/install-template-3.11.yaml --local -p GIT_REPO=<OPERATOR_GIT_REPOSITORY_URL> | oc -n super-project-operator  apply -f-






