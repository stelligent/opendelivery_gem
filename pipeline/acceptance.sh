echo checking out revision $SHA
git checkout $SHA

bundle install
bundle exec rspec --tag slow