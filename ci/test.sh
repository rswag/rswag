#!/usr/bin/env bash

ROOT_PATH=$PWD
set -e # abort if anything fails

echo '####################'
echo 'Unit Tests'
echo '####################'
echo ''

echo '##### rswag-api #####'
cd $ROOT_PATH/rswag-api
xvfb-run bundle exec rspec

echo '##### rswag-specs #####'
cd $ROOT_PATH/rswag-specs
xvfb-run bundle exec rspec

echo '##### rswag-ui #####'
cd $ROOT_PATH/rswag-ui
xvfb-run bundle exec rspec

echo '####################'
echo 'Integration Tests'
echo '####################'
echo ''

echo '##### test-app #####'
cd $ROOT_PATH/test-app
xvfb-run bundle exec rake db:migrate db:test:prepare
xvfb-run bundle exec rspec

# Cleanup
cd $ROOT_PATH
