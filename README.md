# AionCLI

AionCLI is a collection of scripts mainly for handling csv files.

## Installation

Make sure you have rbenv installed.
This can be done through homebrew

    $ brew install rbenv ruby-build
    
Install ruby version 2.5.1

    $ rbenv install 2.5.1

Clone the repo to some folder.
Put an executable somewhere in your path with the following: 

    #!/usr/bin/env bash

    # Switch to ruby 2.5.1
    eval "$(rbenv init -)"
    rbenv shell 2.3.4

    # Trigger script
    BUNDLE_GEMFILE=/path/to/aion_cli/Gemfile bundle exec /path/to/aion_cli/bin/aion $@

Correct the path to fit your setup.

## Usage

    $ aion
