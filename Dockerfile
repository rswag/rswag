FROM ruby:3.3
ENV RAILS_VERSION=7.2.0

RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
&& echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
&& apt update && apt install nodejs -y --no-install-recommends

# Run docker as a non-root user to avoid having to chown generated files while developing
ENV APP_PATH=/rswag/
ENV BUNDLE_PATH=/usr/local/bundle
ARG USER_ID=1000
RUN useradd -lmd ${APP_PATH} appuser -u ${USER_ID} && chown appuser:appuser ${APP_PATH}
USER appuser
WORKDIR ${APP_PATH}

COPY --chown=appuser:appuser . ${APP_PATH}
RUN "./ci/build.sh"

# Configure the main process to run when running the image
EXPOSE 3000
WORKDIR /rswag/test-app
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
