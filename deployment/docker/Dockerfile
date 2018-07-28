FROM ruby:2.5.1

ENV RAILS_ENV "production"
ENV RAILS_LOG_TO_STDOUT "true"
ENV RAILS_SERVE_STATIC_FILES "true"

ARG DEBIAN_FRONTEND="noninteractive"
ARG APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE="true"

RUN apt-get -y update && apt-get -y install apt-utils apt-transport-https --no-install-recommends
RUN curl -sSL https://deb.nodesource.com/setup_9.x | bash -
RUN curl -sSL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get -y update && apt-get -y install nodejs yarn --no-install-recommends

ADD radarmatic /app
WORKDIR /app

RUN bin/bundle config --local build.nokogiri "--use-system-libraries" && \
    bin/bundle config --local deployment 1 && \
    bin/bundle install --jobs 4 --retry 3 --clean --without=development:test
RUN bin/yarn install
RUN bin/rails assets:precompile
RUN bin/rails db:setup

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

EXPOSE 80

CMD ["bin/rails", "server", "-b", "0.0.0.0"]
