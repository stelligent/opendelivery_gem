#!/bin/bash -e

# lookup the SHA of the latest commit
GIT_SHA=`git log | head -1 | awk '{ print $2 }'`

# push instance id into file so we can load it into the environment
echo SHA=$GIT_SHA > environment.txt