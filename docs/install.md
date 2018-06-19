
# Installing Degust locally.
If you just want to use Degust, go [here](http://degust.erc.monash.edu)


Clone degust:

`
git clone https://github.com/drpowell/degust
`

Install rbenv and Ruby.
```
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
exec $SHELL
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc
exec $SHELL
rbenv install 2.4.0
rbenv global 2.4.0
ruby -v
```
Install bundler and build Degust:
```
gem install bundler

bundle install

rake degust:deps
rake degust:build RAILS_ENV=production
```

After building Degust, there are a few dependencies left.

Install R and R libraries:
```
# Install R
apt-key adv --keyserver keyserver.ubuntu.com --recv-key 'E19F5F87128899B192B1A2C2AD5F960A256A04AF'
echo 'deb http://cran.rstudio.org/bin/linux/debian jessie-cran34/'
apt-get update && apt-get install -y r-base

# Install R libs
Rscript -e "install.packages(c('seriation', 'jsonlite'), repos='http://cran.rstudio.org')"
Rscript -e "source('http://bioconductor.org/biocLite.R'); biocLite('limma'); biocLite('edgeR')"
```

Make some required directories:

`
mkdir -p uploads log tmp/pids tmp/cache tmp/sockets tmp/R-cache
`

Setup database:

`
rake db:migrate
`

Run Degust:

`rails s` or `rails s -b 0.0.0.0`

For login with Twitter/Google to work, please consult: [Twitter](https://developer.twitter.com/en/docs/twitter-for-websites/log-in-with-twitter/login-in-with-twitter.html) or [Google](https://developers.google.com/identity/sign-in/web/sign-in).
Once setup, add secrets to environment and launch Rails server as normal.