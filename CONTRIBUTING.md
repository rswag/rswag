# Contributing

Fork, then clone the repo:

```
git clone git@github.com:your-username/swagger_rails.git
cd swagger_rails
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

Push to your fork and [submit a pull request][pr].

[pr]: https://github.com/domaindrivendev/swagger_rails/compare/
