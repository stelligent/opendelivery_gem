#!/bin/bash -ex
set -o pipefail

set +x
if [[ -z ${rubygems_api_key} ]];
then
  echo rubygems_api_key must be set in the environment
  exit 1
fi
set -x

git config --global user.email "build@build.com"
git config --global user.name "build"

set +ex
echo :rubygems_api_key: ${rubygems_api_key} > ~/.gem/credentials
set -ex
chmod 0600 ~/.gem/credentials

#gem used manual versioning up through 0.4.3, so start off
#at 0.4.4 and just keep "patching" through 0.4.N
#might have been less surprising to restart at 0.5.x given we are nuking so much
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

#on circle ci - head is ambiguous for reasons that i don't grok
#we haven't made the new tag and we can't if we are going to annotate
head=$(git log -n 1 --oneline | awk '{print $1}')

echo "Remember! You need to start your commit messages with #x, where x is the issue number your commit resolves."
issues=$(git log v0.4.${current_version}..${head} --oneline | awk '{print $2}' | grep '^#' | uniq)

git tag -a v${new_version} -m "Issues with commits, not necessarily closed: ${issues}"

git push --tags

gem build opendelivery.gemspec
gem push opendelivery-*.gem
