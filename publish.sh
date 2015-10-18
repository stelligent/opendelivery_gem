#!/bin/bash -ex

if [[ -z ${rubygems_api_key} ]];
then
  echo rubygems_api_key must be set in the environment
  exit 1
fi

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
  #for issue scraping
  current_version=origin

  new_version='0.4.4'
else
  new_version=0.4.$((current_version+1))
fi

sed -i "s/0\.0\.0/${new_version}/g" opendelivery.gemspec
cat opendelivery.gemspec

issues=$(git log v${current_version}..${GIT_SHA} --oneline | awk '{print $2}' | grep ^\# | uniq)

git tag -a v${new_version} -m "Issues with commits, not necessarily closed: ${issues}"

git push --tags

gem build opendelivery.gemspec
gem push opendelivery-*.gem
