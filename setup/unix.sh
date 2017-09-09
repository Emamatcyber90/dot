#!/bin/bash -e

# Installs things that I use on all Unix systems (e.g. macOS and Linux).

. $(dirname $0)/../helpers/setup.sh # Load helper script from gcfg/helpers.

# Set default shell to zsh (or $NEWSHELL if set).

# $SHELL isn't updated until we logout, so check whether chsh was already run.
if [ "$(uname)" = Darwin ]; then # macOS
  shell=$(dscl . -read $HOME UserShell)
elif [ "$(uname)" = Linux ]; then # Linux.
  shell=$(cat /etc/passwd | grep $USER | awk -F : '{print $NF}')
fi
# Fall back to $SHELL if that doesn't work.
shell=${shell:-$SHELL}
if [ -z "$ZSH_VERSION" -a "${shell##*/}" != zsh ]; then
  NEWSHELL=${NEWSHELL-$(cat /etc/shells | grep zsh | tail -1)} # Set NEWSHELL for a different shell.
  if [ -e "$NEWSHELL" ]; then
    get "Shell change (Current shell is $shell, changing to $NEWSHELL)."
    chsh -s "$NEWSHELL" || skip "Shell change (chsh failed)."
  else
    skip "Shell change (current shell is $shell (\$SHELL=$SHELL) but shell $NEWSHELL (zsh) doesn't exist)
    Install zsh and then run chsh -s /path/to/zsh"
  fi
else
  skip "Shell change ($shell is already the default shell)"
fi

# Change git user.name and user.email
if exists git && [ "$(whoami)" != gib ] && {
 grep -q 'name = Gibson Fahnestock # REPLACEME' "$XDG_CONFIG_HOME/git/config" ||
 grep -q 'email = gibfahn@gmail.com # REPLACEME' "$XDG_CONFIG_HOME/git/config"
}; then
  if [ -e "$HOME/.gitconfig" ]; then
    GITNAME=$(git config --global user.name)
    GITEMAIL=$(git config --global user.email)
    get "Git Config (moving ~/.gitconfig to ~/backup/.gitconfig, preserving name as '$GITNAME' and email
    as '$GITEMAIL'. Make sure to move any settings you want preserved across)."
    mv "$HOME/.gitconfig" "$HOME/backup/.gitconfig"
    git config --global user.name "$GITNAME"
    git config --global user.email "$GITEMAIL"
  fi
  if [ -z "$GITNAME" -o "$(git config --global user.name)" = "Gibson Fahnestock" ]; then
    read -p "Git name not set, what's your full name? " GITNAME
    git config --global user.name "$GITNAME"
  fi
  if [ -z "$GITEMAIL" -o "$(git config --global user.email)" ]; then
    read -p "Git email not set, what's your email address? " GITEMAIL
    git config --global user.email "$GITEMAIL"
  fi
  get "Git Config (git name set to $(git config --global user.name) and email set to $(git config --global user.email))"
fi

# Set up a default ssh config
if [ ! -e ~/.ssh/config ]; then
  get "SSH Config (copying default)."
  [ ! -d ~/.ssh ] && mkdir ~/.ssh && chmod 700 ~/.ssh || true
  cp $(dirname $0)/config/ssh-config ~/.ssh/config
else
  skip "SSH Config (not overwriting ~/.ssh/config, copy manually from ./config/ssh-config as necessary)."
fi

# Install oh-my-zsh:
if exists zsh && no oh-my-zsh; then
  # Don't run the setup script, we don't need it and it checks $SHELL which
  # we've only just changed. Just put it in the right place.
  gitClone robbyrussell/oh-my-zsh "$XDG_DATA_HOME/oh-my-zsh"
fi

# Set up autocompletions:
if exists zsh && no zfunc; then mkdir -p "$XDG_DATA_HOME/zfunc"; fi

# Set up zsh scripts:
if exists zsh && no zsh; then mkdir -p "$XDG_DATA_HOME/zsh"; fi

if exists zsh && no zsh/zsh-syntax-highlighting; then
  gitClone zsh-users/zsh-syntax-highlighting "$XDG_DATA_HOME/zsh/zsh-syntax-highlighting"
fi

# Install nvm:
if no nvm; then
  # No install scripts as path update isn't required, it's done in gibrc.
  gitClone creationix/nvm "$XDG_DATA_HOME/nvm"
  . "$XDG_DATA_HOME"/nvm/nvm.sh # Load nvm so we can use it below.
  nvm install stable # Install the latest LTS version of node.

  # Autocompletion for npm (probably needed)
  mkdir -p "$XDG_DATA_HOME/.zfunc"
  npm completion > "$XDG_DATA_HOME/.zfunc/_npm"
fi

# Install vim-plug (vim plugin manager):
if no nvim/site/autoload/plug.vim; then
  curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  exists() { type "$1" >/dev/null 2>&1; } # Check if command exists (is in path).
  unset VIM
  { exists nvim && VIM=nvim; } || { exists vim && VIM=vim; } # Take what you can get.
  [ "$VIM" = vim ] && mkdir -p ~/.vim && ln -s ~/.local/share/nvim/site/autoload ~/.vim/autoload
  exists $VIM && $VIM +PlugInstall +qall # Install/update vim plugins.
fi

# If you don't use rust just choose the cancel option.
if [ "$HARDCORE" ] && { no rustup || no cargo; }; then # Install/set up rust.
  # Install rustup. Don't modify path as that's already in gibrc.
  curl https://sh.rustup.rs -sSf | bash -s -- --no-modify-path
  # Download zsh completion
  exists zsh && curl https://raw.githubusercontent.com/rust-lang-nursery/rustup.rs/master/src/rustup-cli/zsh/_rustup >"$XDG_DATA_HOME/zfunc/_rustup"

  if [ ! -d "$HOME/.rustup" ]; then
    # Move to proper directories
    mv "$HOME/.rustup" "$XDG_DATA_HOME/rustup"
    mv "$HOME/.cargo" "$XDG_DATA_HOME/cargo"
  fi

  # Rustup seems to respect the RUSTUP_HOME and CARGO_HOME env vars, but IDK.
  export PATH="$CARGO_HOME/bin:~/.cargo/bin:$PATH"

  # Install stable and nightly.
  rustup install nightly
  rustup install stable

  # Download src (docs are included by default).
  rustup component add rust-src
fi
