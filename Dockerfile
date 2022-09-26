FROM ruby:2.7
ENV RAILS_VERSION 7.0.3.1

RUN apt-get update -qq && apt-get install -y nodejs npm
# Bugfix for https://github.com/rubyjs/mini_racer/issues/220#issuecomment-1010724771
RUN gem update --system

# Run docker as a non-root user to avoid having to chown generated files while developing
ENV APP_PATH=/rswag/
ENV BUNDLE_PATH=/usr/local/bundle
ARG USER_ID=1000
RUN useradd -md ${APP_PATH} appuser -u ${USER_ID} && chown appuser:appuser ${APP_PATH}
USER appuser
WORKDIR ${APP_PATH}

COPY --chown=appuser:appuser . ${APP_PATH}
RUN "./ci/build.sh"

# Configure the main process to run when running the image
EXPOSE 3000
WORKDIR /rswag/test-app
CMD ["rails", "server", "-b", "0.0.0.0"]
