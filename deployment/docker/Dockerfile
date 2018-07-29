FROM ruby:2.5.1

ENV RAILS_ENV "production"
ENV RAILS_LOG_TO_STDOUT "true"
ENV RAILS_SERVE_STATIC_FILES "true"

ARG DEBIAN_FRONTEND="noninteractive"
ARG APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE="true"

ADD radarmatic /app
WORKDIR /app

RUN apt-get -y update && apt-get -y install apt-utils apt-transport-https --no-install-recommends && \
    curl -ssL https://deb.nodesource.com/setup_10.x | bash - && \
    curl -sSL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get -y update && apt-get -y install build-essential nodejs yarn --no-install-recommends && \
    bin/bundle config --local build.nokogiri "--use-system-libraries" && \
    bin/bundle config --local deployment 1 && \
    bin/bundle install --jobs 4 --retry 3 --without=development:test && \
    bin/rails yarn:install && \
    bin/rails assets:precompile && \
    bin/rails db:setup && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

EXPOSE 80

CMD ["bin/rails", "server"]
