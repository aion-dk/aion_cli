# AionCLI

AionCLI is a collection of scripts mainly for handling csv files.

## Installation

Make sure you have rbenv installed. This can be done through homebrew.

Follow the instructions on how to setup homebrew:
https://brew.sh/index_da

After this, install rbenv using the following command:

    $ brew install rbenv ruby-build

Follow the instructions on how to setup rbenv:
https://github.com/rbenv/rbenv#homebrew-on-macos

Install a ruby version to use:

    $ rbenv install 2.5.3

Clone the repository to a some folder, and navigate to it:

    $ git clone https://github.com/aion-dk/aion_cli.git 
    $ cd aion_cli

Specify an installed ruby version to use:

    $ rbenv local 2.5.3
    
Install bundler, pull gems and install the aion script:

    $ gem install bundler
    $ bundle install
    $ bundle exec aion install

You should be ready to go :-)

## Usage

    $ aion
