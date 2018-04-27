#!/usr/bin/env bash

ROOT_PATH=$PWD
set -e # abort if anything fails

echo '####################'
echo 'bundle'
echo '####################'
echo ''

echo '##### all #####'
bundle install

echo '####################'
echo 'npm'
echo '####################'
echo ''

echo '##### rswag-ui #####'
cd $ROOT_PATH/rswag-ui
npm install

# Cleanup
cd $ROOT_PATH
