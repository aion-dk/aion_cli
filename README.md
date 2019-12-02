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

Clone the repository to some folder, and navigate to it:

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

### AVX usage
1. Generate n credential pairs, which consist of an election code and a public key. The credential pairs will be printed 
in the terminal. The following command takes as arguments:
   - n, the number of credential pairs
   ```
   $ aion avx generate n
   ```

2. Reads a csv file and generate credential pairs for each entry of the file. Generates two new files with the initial
content plus an extra column for election code or public key, respectively.
The following command takes as arguments:
    - the path to the csv file
   ```
   $ aion avx generate_in_file file_path
   ```

3. Combine multiple public key files into one main public key file. The input files are the ones received from each
credential authority. The output public key file is the one that needs to be imported into the AVX system.
The script has an interactive behaviour and the user needs to specify the column used as the voter identifier. The user
also needs to specify the name of the output file.
The script expects that all input files have the same data structure (csv files have the same columns) and that the data
from all files is consistent (the identifier column is identical in all files).
The following command takes as arguments:
   - a list of all the paths to the public key files, separated by space
   ```
   $ aion avx aggregate_public_keys file1_path file2_path file3_path
   ```
