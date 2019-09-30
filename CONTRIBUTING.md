# Contributing

Fork, then clone the repo:

```
git clone git@github.com:domaindrivendev/rswag.git
cd rswag
```

Set up your machine:

```
bundle
cd spec/dummy
bundle exec rake db:setup
cd -
```

Make sure the tests pass:

```
bundle exec rspec
```

Make your change. Add tests for your change. Make the tests pass:

```
bundle exec rspec
```

Push to your fork and [submit a Pull Request][pr].

[pr]: https://github.com/domaindrivendev/rswag/compare/
