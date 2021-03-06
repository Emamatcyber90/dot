#!/bin/bash
# shellcheck shell=bash disable=SC1090,SC2016

# Things I like to have on a Mac.

. "$(dirname "$0")/../helpers/setup.sh" # Load helper script from dot/helpers.

if ! grep -q gib ~/Library/Preferences/com.apple.Terminal.plist; then
  get "gib Terminal profile."
  # Install my terminal profile.
  open "$(dirname "$0")/config/gib.terminal"

  # Change the default to my profile (swap it back in settings if you want).
  if [[ "$(defaults read com.apple.Terminal "Default Window Settings")" != gib ]]; then
    defaults write com.apple.Terminal "Default Window Settings" gib
  fi
else
  skip "gib Terminal profile (already installed)."
fi

# Link VS Code preferences into the macOS specific folder.
if [[ -d "$HOME/Library/Application Support/Code/" ]]; then
  for file in "$HOME"/.config/code/*.json; do
    ln -sf "$file" "$HOME/Library/Application Support/Code/User/$(basename "$file")"
  done
fi

# Install xcode command line tools
if ! xcode-select -p &>/dev/null; then
  skip "Xcode Command Line Tools."
  xcode-select --install
else
  skip "Xcode Command Line Tools (already installed)."
fi

if [ "$HARDCORE" ]; then # Set keyboard preferences.
  get "Setting macOS defaults."

  # Set Keyboard Shortcuts -> App Shortcuts
  # To add your own, first add them in System Preferences -> Keyboard ->
  # Shortcuts -> App Shortcuts, then find them in the output of:
  #   defaults find NSUserKeyEquivalents
  # Use the existing and the help output of `defaults` to work it out.
  #   @command, ~option, ^ctrl, $shift
  # The global domain NSGlobalDomain NSGlobalDomain is the same as -g or -globalDomain.
  # -bool YES/TRUE or FALSE/NO correspond to -int 1 or 0.

  # Create global shortcut "Merge all windows" ⌘-M
  updateMacOSKeyboardShortcut NSGlobalDomain "Merge All Windows" '@$m'

  # Remove ⌘-h as a Hide Window shortcut in relevant apps.
  # -> IntelliJ Community Edition:
  # Removed because I haven't installed it.
  # updateMacOSKeyboardShortcut com.jetbrains.intellij.ce "Hide IntelliJ IDEA" '@~^\\U00a7'
  # -> IntelliJ:
  updateMacOSKeyboardShortcut com.jetbrains.intellij "Hide IntelliJ IDEA" '~^$\\U00a7'
  # -> Kitty:
  updateMacOSKeyboardShortcut net.kovidgoyal.kitty "Hide kitty" '~^$\\U00a7'
  # -> Mail: ⌘-backspace moves to Archive.
  updateMacOSKeyboardShortcut com.apple.mail "Archive" '@\\b'
  # -> Mail: ⌘-Enter sends the message.
  updateMacOSKeyboardShortcut com.apple.mail "Send" '@\\U21a9'

  # Radar: Ctrl-Alt-C copies as Markdown:
  updateMacOSKeyboardShortcut com.apple.ist.Radar7 "Copy as Markdown" "~^c"

  # Set up fastest key repeat rate (needs relogin).
  updateMacOSDefault NSGlobalDomain KeyRepeat -int 1

  # Sets a low time before key starts repeating.
  updateMacOSDefault NSGlobalDomain InitialKeyRepeat -int 8

  # Increases trackpad sensitivity (SysPref max 3.0).
  updateMacOSDefault NSGlobalDomain com.apple.trackpad.scaling -float 5

  # Disables window minimizing animations.
  updateMacOSDefault NSGlobalDomain NSAutomaticWindowAnimationsEnabled -int 0

  # Always open new things in tabs (not new windows) for document based apps.
  updateMacOSDefault NSGlobalDomain AppleWindowTabbingMode -string always

  # Greys out hidden apps in the dock (so you can see which are hidden).
  updateMacOSDefault com.apple.Dock showhidden -int 1 && killall Dock

  # System Preferences -> Keyboard -> Shortcuts -> Full Keyboard Access
  # Full Keyboard Access: In Windows and Dialogs, press Tab to move keyboard
  # focus between:
  #   0: Text Boxes and Lists only
  #   2: All controls
  # Set it to 2 because that's much nicer (you can close confirmation prompts
  # with the keyboard, Enter to press the blue one, tab to select between them,
  # space to press the Tab-selected one. If there are underlined letters, hold
  # Option and press the letter to choose that option.
  updateMacOSDefault NSGlobalDomain AppleKeyboardUIMode -int 2

  # Show hidden files in the finder.
  oldFinderValue="$(defaults read com.apple.finder QuitMenuItem)"
  updateMacOSDefault com.apple.finder AppleShowAllFiles -int 1
  if [[ "$oldFinderValue" != 1 ]]; then
    killall Finder
    open ~
  fi

  # Allow text selection in any QuickLook window.
  updateMacOSDefault NSGlobalDomain QLEnableTextSelection -int 1

  # Allow Finder to be quit (hides Desktop files).
  oldFinderValue="$(defaults read com.apple.finder QuitMenuItem)"
  updateMacOSDefault com.apple.finder QuitMenuItem -int 1
  if [[ "$oldFinderValue" != 1 ]]; then
    killall Finder
    open ~
  fi

  # Disable the animations for opening Quick Look windows
  updateMacOSDefault NSGlobalDomain QLPanelAnimationDuration -float 0

  # System Preferences > General > Click in the scrollbar to: Jump to the spot that's clicked
  updateMacOSDefault NSGlobalDomain AppleScrollerPagingBehavior -int 1

  # TODO(gib): Add more shortcuts:
  #
  # Make changing windows quicker with keyboard.
  #   defaults write com.apple.dock expose-animation-duration -float 0.1
  # Don't wait to hide the dock.
  #   defaults write com.apple.Dock autohide-delay -float 0
  # Reduce motion (fewer distracting animations).
  #   defaults write com.apple.universalaccess reduceMotion -bool true
  # Increase window resize speed for Cocoa animations
  #   defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
  # Have the Dock show only active apps
  #   defaults write com.apple.dock static-only -bool true; killall Dock
  # Remove dock animation animation.
  #   defaults write com.apple.dock autohide-time-modifier -float 1; killall Dock
  # https://github.com/pawelgrzybek/dotfiles/blob/master/setup-macos.sh
  # https://github.com/mathiasbynens/dotfiles/blob/master/.macos
  # https://github.com/kevinSuttle/macOS-Defaults
  # Show path bar in finder:
  #   defaults write com.apple.finder ShowPathbar -bool true
  # Cmd-Enter sends email in Mail.

else
  skip "Not setting macOS defaults (HARDCORE not set)."
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

# Increase max file watch limit. See http://entrproject.org/limits.html
if [[ -e /Library/LaunchDaemons/limit.maxfiles.plist ]]; then
  skip "File watcher limit (already increased)."
else
  get "File watcher limit."
  sudo curl -sL http://entrproject.org/etc/limit.maxfiles.plist -o /Library/LaunchDaemons/limit.maxfiles.plist
fi

# Install brew
if exists brew; then
  skip "brew (already installed)."
else
  get "brew."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

sogou_dir_old="$(ls -a /usr/local/Caskroom/sogouinput 2>/dev/null || true)"
# brew install things. Edit config/Brewfile to adjust.
get "brew installing/updating."
brew tap Homebrew/bundle
brew bundle --file="$(dirname "$0")"/config/Brewfile | grep -Evx "Using [-_/0-9a-zA-Z]+"

if [ "$HARDCORE" ]; then # Set up HARDCORE brew packages.
  get "brew HARDCORE packages."
  brew bundle --file="$(dirname "$0")"/config/Brewfile-hardcore | grep -Evx "Using [-_/0-9a-zA-Z]+"
else
  skip "brew HARDCORE packages (HARDCORE not specified)."
fi

# Upgrade everything, even things that weren't in your Brewfile.
brew upgrade
brew cask upgrade # You may occasionally want to run `brew cask upgrade --greedy` in case built-in updaters aren't working.

sogou_dir_new="$(ls -a /usr/local/Caskroom/sogouinput 2>/dev/null || true)"
# If sogouinput was updated
if [[ "$sogou_dir_old" != "$sogou_dir_new" ]]; then
  update "Sogou Input"
  sogou_dir="$(brew cask info sogouinput | awk '/^\/usr\/local\/Caskroom\/sogouinput\// { print $1 }')"
  [[ -n "$sogou_dir" ]] && open "$sogou_dir"/sogou*.app
fi

# Update Mac App Store apps.
softwareupdate -i -a

if not langserver-swift && ! not swift; then
  gitClone rlovelett/langserver-swift "$HOME"/bin/src/langserver-swift
  (cd "$HOME/bin/src/langserver-swift" || error "Failed to cd to the langserver directory"; make release)
  ln -s "$HOME/bin/src/langserver-swift/.build/$(uname -m)"-*/release/langserver-swift "$HOME"/bin/langserver-swift
fi

if [[ -d /Applications/Slack.app ]]; then
  slack_path=/Applications/Slack.app/Contents/Resources/app.asar.unpacked/src/static/ssb-interop.js
  [[ -e $slack_path ]] || skip "Slack path doesn't exist, unable to modify it"
  if ! grep -q raw.githubusercontent.com $slack_path; then
    get "Slack dark mode tweak"
    cat "$(dirname "$0")/optional/slack-black.js" >> "$slack_path"
  else
    skip "Slack dark mode tweak"
  fi
fi
