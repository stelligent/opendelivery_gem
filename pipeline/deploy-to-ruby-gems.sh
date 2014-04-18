echo checking out revision $SHA
git checkout $SHA

rm -rf opendelivery-*.gem

gem build opendelivery.gemspec 
gem push opendelivery-*.gem
