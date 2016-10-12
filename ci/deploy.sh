#!/usr/bin/env bash

ROOT_PATH=$PWD
set -e # abort if anything fails

bundle check || bundle

echo '####################'
echo 'Build Gems'
echo '####################'
echo ''

echo '##### rswag-api #####'
cd $ROOT_PATH/rswag-api
gem build rswag-api.gemspec

echo '##### rswag-specs #####'
cd $ROOT_PATH/rswag-specs
gem build rswag-specs.gemspec

echo '##### rswag-ui #####'
cd $ROOT_PATH/rswag-ui
gem build rswag-ui.gemspec

echo '##### rswag #####'
cd $ROOT_PATH/rswag
gem build rswag.gemspec

echo '####################'
echo 'Push to RubyGems'
echo '####################'
echo ''

# Cleanup
cd $ROOT_PATH
