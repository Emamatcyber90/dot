# Install xcode command line tools
xcode-select --install

# Set up fastest key repeat rate (needs relogin).
defaults write NSGlobalDomain KeyRepeat -int 1
# Sets a low time before key starts repeating.
defaults write NSGlobalDomain InitialKeyRepeat -int 8
# Increases trackpad sensitivity (SysPref max 3.0).
defaults write -g com.apple.trackpad.scaling -float 5.0

# Tell Hammerspoon to use $XDG_CONFIG_HOME.
defaults write org.hammerspoon.Hammerspoon MJConfigFile "$XDG_CONFIG_HOME/hammerspoon/init.lua"

# Install brew
if which brew; then
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi
# Install cask (brew for GUI utils)
brew tap caskroom/cask

# Brew stuff
brew install bash zsh git rmtrash # rmtrash = move to trash
brew install entr # Run command on file change
brew install gnu-sed gnu-tar gnu-which htop perl tree wget
brew install binutils coreutils findutils neovim tig zsh ctags
brew install dfu-util # Ergodox
brew install ninja python python3 ccache gdb # Build utilities
# brew install fzf # Fuzzy finder used in vim
# brew install exercism # Am I still doing this?
# brew install mongodb redis postgresql # Not sure if I'll need these

# Brew cask stuff
brew cask install google-chrome firefox meld
brew cask install gpgtools
brew cask install docker vagrant virtualbox
# brew cask install hammerspoon # Did I even do lua scripting?

# zsh stuff, see ~/.gibrc for loading
brew install zsh-completions zsh-syntax-highlighting
