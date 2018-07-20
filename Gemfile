source "https://rubygems.org"

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem "rails", "~> 5.2.0"
gem "uglifier", ">= 1.3.0"
gem "sqlite3", ">= 1.3.13"
gem "puma", "~> 3.7"
gem "slim", "~> 3.0.8"
gem "rbzip2", "~> 0.3.0"
gem "bootsnap", "~> 1.3.1"
gem "tzinfo-data"

group :development do
  gem "web-console", ">= 3.3.0"
  gem "listen", ">= 3.0.5", "< 3.2"
  gem "awesome_print", require: "ap"
end
