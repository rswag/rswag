# Contributing

🎉 Thanks for taking the time to contribute! 🎉

We put forward the philosophy put forward by the [react community](https://reactcommunity.org/) about ownership, responsibility and avoiding burnout.

We also strive to achieve [semantic versioning](https://semver.org/) for this repo.

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
Initialize the rswag-ui repo with assets.
```
ci/build.sh
```

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

## Updating Swagger UI

Find the latest versions of swagger-ui here:
https://github.com/swagger-api/swagger-ui/releases

Update the swagger-ui-dist version in the rswag-ui dependencies
```
./rswag-ui/package.json
```

Navigate to the rswag-ui folder and run npm install to update the package-lock.json


## Release
(for maintainers)

Update the changelog.md, putting the new version number in and moving the Unreleased marker.

Merge the changes into master you wish to release.

Add and push a new git tag, annotated tags preferred:
```
git tag -s 2.0.6 -m 'v2.0.6'
```

Travis will detect the tag and release all gems with that tag version number.
