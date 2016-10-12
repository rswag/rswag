#!/usr/bin/env bash

ROOT_PATH=$PWD
set -e # abort if anything fails

bundle check || bundle

echo '####################'
echo 'Unit Tests'
echo '####################'
echo ''

echo '##### rswag-api #####'
cd $ROOT_PATH/rswag-api
bundle exec rspec

echo '##### rswag-specs #####'
cd $ROOT_PATH/rswag-specs
bundle exec rspec

echo '##### rswag-ui #####'
cd $ROOT_PATH/rswag-ui
bundle exec rspec

echo '####################'
echo 'Integration Tests'
echo '####################'
echo ''

echo '##### test-app #####'
cd $ROOT_PATH/test-app
bundle exec rspec

# Cleanup
cd $ROOT_PATH
