# AionCLI

AionCLI is a collection of scripts mainly for handling csv files.

## Installation

### Installation instructions

To install the cli, you first need to install the command line tools:

```bash
xcode-select --install 
```

Once that is completed, you can install the cli using these commands:

```bash
mkdir -p ~/repos
cd ~/repos
git clone https://github.com/aion-dk/aion_cli.git &&\
  cd aion_cli &&\
  chmod +x install.sh &&\
  ./install.sh
```

### Manual installation

`install.sh` (above) handles everything: Homebrew, asdf, Ruby 4.0.5, and the `aion`
gem itself. If you already have `asdf` and the required Ruby installed and just want
to (re)install the gem, from the repo root run:
```bash
bundle install && bundle exec rake install:local
```

### Updating the gem
To update the gem, pull the latest changes and reinstall
```bash
git pull --ff &&\
bundle install && bundle exec rake install:local
```

## Usage

    $ aion

### AVX usage
1. Generate n credential pairs, which consist of an election code and a public key. The credential pairs will be printed
in the terminal. The following command takes as arguments:
   - n, the number of credential pairs
   ```
   $ aion avx credentials_print n
   ```

2. Reads a csv file and generates credential pairs for each entry of the file. Generates two new files with the initial
content plus an extra column for election code or public key, respectively.
The following command takes as arguments:
    - the path to the csv file
   ```
   $ aion avx credentials_generate file_path
   ```

3. Reads a csv file and computes public keys from an existing election code column. The script has an interactive
behaviour and the user needs to specify which column to use as election codes.
The following command takes as arguments:
   - the path to the csv file
   ```
   $ aion avx credentials_compute file_path
   ```

4. Combine multiple public key files into one main public key file. The input files are the ones received from each
credential authority. The output public key file is the one that needs to be imported into the AVX system.
The script has an interactive behaviour and the user needs to specify the column used as the voter identifier. The user
also needs to specify the name of the output file.
The script expects that all input files have the same data structure (csv files have the same columns) and that the data
from all files is consistent (the identifier column is identical in all files).
The following command takes as arguments:
   - a list of all the paths to the public key files, separated by space
   ```
   $ aion avx credentials_aggregate file1_path file2_path file3_path
   ```

5. Interactively compute one aggregated public key from a given number of election codes entered at the prompt.
   ```
   $ aion avx one_quick
   ```
