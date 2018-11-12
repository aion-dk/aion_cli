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

Clone the repo to some folder on your machine.

In this example we are using ruby 2.5.3.

Put an executable called `aion` somewhere in your path with the following contents:

```bash
#!/usr/bin/env bash

# Switch to ruby 2.5.3
eval "$(rbenv init -)"
rbenv shell 2.5.3

# Trigger script
BUNDLE_GEMFILE=/path/to/aion_cli/Gemfile bundle exec /path/to/aion_cli/bin/aion $@
```

Correct the path to fit your setup.
Make sure the file is executable:
    
    $ chmod u+x /path/to/aion

Restart your terminal and you should be ready to go :-)

## Usage

    $ aion
