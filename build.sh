#!/bin/bash -e

# For some reason, the Jenkins user doesn't have the path configured correctly...
PATH=$PATH:/usr/local/bin/
echo path: $PATH

# check the syntax of each ruby file
echo Syntax check...
find . -name *.rb | xargs -n1 ruby -c > /dev/null

# Prep and run unit tests
gem install bundler
bundle install
bundle exec rspec spec/ -f d
