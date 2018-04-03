#!/bin/bash

# Things I like to have on a Mac.

. $(dirname $0)/../helpers/setup.sh # Load helper script from dot/helpers.

if ! cat ~/Library/Preferences/com.apple.Terminal.plist | grep -q gib; then
  get "gib Terminal profile."
  # Install my terminal profile.
  open $(dirname $0)/config/gib.terminal
  # Change the default to my profile (swap it back in settings if you want).
  defaults write com.apple.Terminal "Default Window Settings" gib
else
  skip "gib Terminal profile (already installed)."
fi

# Link VS Code preferences into the macOS specific folder.
for file in "$HOME"/.config/code/*.json; do
  ln -sf "$file" "$HOME/Library/Application Support/Code/User/$(basename "$file")"
done

# Install xcode command line tools
if ! xcode-select -p &>/dev/null; then
  skip "Xcode Command Line Tools."
  xcode-select --install
else
  skip "Xcode Command Line Tools (already installed)."
fi

if [ "$HARDCORE" ]; then # Set key repeat preferences.
  get "Setting keyboard/trackpad preferences."
  # Set up fastest key repeat rate (needs relogin).
  defaults write NSGlobalDomain KeyRepeat -int 1
  # Sets a low time before key starts repeating.
  defaults write NSGlobalDomain InitialKeyRepeat -int 8
  # Increases trackpad sensitivity (SysPref max 3.0).
  defaults write -g com.apple.trackpad.scaling -float 5.0
  # Allow Finder to be quit (hides Desktop files).
  defaults write com.apple.finder QuitMenuItem -bool YES
  killall Finder
  open .
else
  skip "Not setting keyboard/trackpad preferences (HARDCORE not set)."
  # You can still change them in System Preferences/{Trackpad,Keyboard}.
fi

# Setup spectacle config.
specConfig="$HOME/Library/Application Support/Spectacle/Shortcuts.json"
if [ ! -L "$specConfig" ]; then
  get "Overwriting Spectacle shortcuts with link to dot ones."
  mkdir -p "$HOME/.backup"
  [ -e "$specConfig" ] && mv "$specConfig" "$HOME/.backup/Shortcuts.json"
  ln -s "$XDG_CONFIG_HOME/Spectacle/Shortcuts.json" "$specConfig"
fi

# Install brew
if exists brew; then
  skip "brew (already installed)."
else
  get "brew."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# brew install things. Edit config/Brewfile to adjust.
get "brew installing/updating."
brew tap Homebrew/bundle
brew bundle --file=$(dirname $0)/config/Brewfile

if [ "$HARDCORE" ]; then # Set up HARDCORE brew packages.
  get "brew HARDCORE packages."
  brew bundle --file=$(dirname $0)/config/Brewfile-hardcore
else
  skip "brew HARDCORE packages (HARDCORE not specified)."
fi

# Upgrade everything, even things that weren't in your Brewfile.
brew upgrade

if not langserver-swift && ! not swift; then
  gitClone rlovelett/langserver-swift "$HOME"/bin/src/langserver-swift
  (cd "$HOME/bin/src/langserver-swift"; make release)
  ln -s "$HOME/bin/src/langserver-swift/.build/$(uname -m)"-*/release/langserver-swift "$HOME"/bin/langserver-swift
fi

