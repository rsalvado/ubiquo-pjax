source "http://rubygems.org"

gem "rails",     "= 2.3.14"
gem "lockfile",  ">= 1.4.3"
gem "i18n",      "< 0.5.0"
gem "rdoc",      ">= 2.4.2"
gem "rack-pjax"

platforms :mri_18 do
  gem "sqlite3"
end

platforms :jruby do
  gem "activerecord-jdbc-adapter", "~> 1.1.1"
  gem "jdbc-sqlite3"
  gem "jruby-openssl", "~> 0.7.3"
end

group :development do
  gem "ruby-debug"
  gem "ya2yaml", ">= 0.2.6"
  gem "highline", ">= 1.5.2"
  gem "ffi-ncurses", "~> 0.3.3", :platforms => :jruby
end

group :test do
  gem "mocha", ">= 0.9.8", :require => false
end
