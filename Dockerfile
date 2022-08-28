FROM ruby:2.7
ENV RAILS_VERSION 7.0.1

RUN apt-get update -qq && apt-get install -y nodejs npm
WORKDIR /rswag
COPY . /rswag

RUN gem update --system
RUN "./ci/build.sh"

# Configure the main process to run when running the image
EXPOSE 3000
WORKDIR /rswag/test-app
CMD ["rails", "server", "-b", "0.0.0.0"]
