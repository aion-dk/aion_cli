#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# 1. Install Homebrew
if ! command -v brew &> /dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Ensure brew is in PATH for the remainder of the script
  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
else
  echo "Homebrew is already installed. Skipping..."
fi

# Helper function for idempotent brew installs
install_brew_package() {
  if ! brew list "$1" &> /dev/null; then
    echo "Installing $1..."
    brew install "$1"
  else
    echo "$1 is already installed. Skipping..."
  fi
}

# 2. Install required brew packages
echo "Checking brew dependencies..."
for pkg in openssl@3 readline libyaml gmp autoconf asdf icu4c xz; do
  install_brew_package "$pkg"
done

# 3. Add asdf ruby plugin
if ! asdf plugin list 2>/dev/null | grep -q "^ruby$"; then
  echo "Adding asdf ruby plugin..."
  asdf plugin add ruby https://github.com/asdf-vm/asdf-ruby.git
else
  echo "asdf ruby plugin already added. Skipping..."
fi

# Make sure asdf shims are in path
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

# Persist the shims PATH entry in ~/.zshrc if it isn't already there
ASDF_SHIMS_LINE='export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"'
ZSHRC="$HOME/.zshrc"
touch "$ZSHRC"

if ! grep -qxF "$ASDF_SHIMS_LINE" "$ZSHRC"; then
  echo "Adding asdf shims to PATH in $ZSHRC..."
  {
    echo ""
    echo "# asdf shims (added by aion_cli install script)"
    echo "$ASDF_SHIMS_LINE"
  } >> "$ZSHRC"
else
  echo "asdf shims already configured in $ZSHRC. Skipping..."
fi

# 4. Install and set global ruby version
RUBY_VERSION="4.0.5"

echo "Setting global ruby version to $RUBY_VERSION..."
asdf set --home ruby "$RUBY_VERSION"
if ! asdf list ruby 2>/dev/null | grep -q "$RUBY_VERSION"; then
  echo "Installing Ruby $RUBY_VERSION..."
  asdf install
else
  echo "Ruby $RUBY_VERSION is already installed. Skipping..."
fi

# 5. Install bundler
# The -i flag checks if the gem is installed quietly
if ! gem list -i "^bundler$" &> /dev/null; then
  echo "Installing bundler..."
  gem install bundler
else
  echo "Bundler is already installed. Skipping..."
fi

# 6. Configure Bundler
# If you uncomment this, using $(brew --prefix icu4c) dynamically finds the right path
# bundle config build.charlock_holmes --with-icu-dir="$(brew --prefix icu4c)"

# 7. Installing the gem

# build gem and install local file
bundle install
bundle exec rake install:local

echo "Setup complete!"
