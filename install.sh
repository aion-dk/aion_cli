#! /bin/bash

# Install homebrew

/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# required packages for OSx

brew install coreutils automake autoconf openssl libyaml readline libxslt libtool unixodbc

# Install asdf version manager

git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.3.0

# Add to bash profile

echo -e '\n. $HOME/.asdf/asdf.sh' >> ~/.bash_profile
echo -e '\n. $HOME/.asdf/completions/asdf.bash' >> ~/.bash_profile

# Add ruby plugin

asdf plugin-add ruby https://github.com/asdf-vm/asdf-ruby

# set global ruby version

asdf global ruby 2.4.2

# Install ruby

asdf install

# Brew install charlock_holmes

brew install icu4c

# Configure Bundler to always use the correct arguments when installing

bundle config build.charlock_holmes --with-icu-dir=/usr/local/opt/icu4c

