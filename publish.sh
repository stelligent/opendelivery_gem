#!/bin/bash -ex
git config --global user.email "build@build.com"
git config --global user.name "build"

echo :rubygems_api_key: ${rubygems_api_key} > ~/.gem/credentials
chmod 0600 ~/.gem/credentials

#gem used manual versioning up through 0.4.3, so start off
#at 0.4.4 and just keep "patching" through 0.4.N
current_version=$(ruby -e 'tags=`git tag -l v0\.4\.*`' \
                       -e 'p tags.lines.map { |tag| tag.sub(/v0.4./, "").chomp.to_i }.max')

if [[ ${current_version} == nil ]];
then
  new_version='0.4.4'
else
  new_version=0.4.$((current_version+1))
fi

sed -i "s/0\.0\.0/${new_version}/g" opendelivery.gemspec
cat opendelivery.gemspec

git tag v${new_version}

git push --tags

gem build opendelivery.gemspec
gem push opendelivery-*.gem
