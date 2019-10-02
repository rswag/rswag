# Contributing

## Fork, then clone the repo:
```
git clone git@github.com:rswag/rswag.git
cd rswag
```

## Build
Set up your machine:
```
./ci/build.sh
```
Or manually
```
bundle
cd test-app
bundle exec rake db:setup
cd -

cd rswag-ui
npm install
cd -
```

## Test
Make sure the tests pass:
```
./ci/test.sh
```
or manually
```
cd test-app
bundle exec rspec
```

Make your change. Add tests for your change. Make the tests pass:

```
bundle exec rspec
```

Push to your fork and [submit a Pull Request][pr].

[pr]: https://github.com/rswag/rswag/compare/
