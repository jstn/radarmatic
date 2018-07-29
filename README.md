# Radarmatic

### New and improved.

[radarmatic.com](http://radarmatic.com/)

Requires: Ruby, Yarn, Git, Docker (optional).

Local installation:

    git clone https://github.com/jstn/radarmatic.git --depth 1
    cd radarmatic
    bin/bundle install
    bin/rails yarn:install
    bin/rails db:create
    bin/rails db:migrate
    bin/rails db:seed
    bin/rails server

Docker deployment:

    git clone https://github.com/jstn/radarmatic.git --depth 1
    cd radarmatic/deployment
    ./build.sh master
    ./run.sh master
