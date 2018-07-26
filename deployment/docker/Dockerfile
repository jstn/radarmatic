FROM phusion/passenger-full:0.9.34

EXPOSE 80

ENV RAILS_ENV "production"
ENV HOME "/root"
ENV TZ "Etc/UTC"

RUN echo $TZ | tee /etc/timezone
RUN rm /etc/localtime && ln -s /usr/share/zoneinfo/$TZ /etc/localtime

RUN curl -sSL https://deb.nodesource.com/setup_9.x | bash -
RUN curl -sSL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get -y update && apt-get -y install nodejs yarn
RUN bash -lc "rvm --default use ruby-2.5.1 && gem install bundler"

ADD radarmatic /home/app/radarmatic
RUN chown -R app:app /home/app/radarmatic

WORKDIR /home/app/radarmatic
RUN su app -c "bin/bundle config git.allow_insecure true && bin/bundle install --without=development test"
RUN su app -c "bin/yarn install && bin/rails assets:precompile"
RUN su app -c "bin/rails db:create && bin/rails db:migrate && bin/rails db:seed"

ADD site-default.conf /etc/nginx/sites-available/default
RUN rm -f /etc/service/nginx/down

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

CMD ["/sbin/my_init"]
