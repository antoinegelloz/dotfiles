#!/bin/bash

# Install Oh-My-Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

BACKUP_DIR=~/dotfiles.backup
echo -n "Creating $BACKUP_DIR to backup any existing dotfiles in $HOME"
mkdir -p $BACKUP_DIR

echo "Moving any existing dotfiles from $HOME to $BACKUP_DIR"
FILES="gitconfig gitignore vimrc zshrc"
for FILE in $FILES; do
    mv ~/.$FILE $BACKUP_DIR || true
    echo "Creating symlink to '$FILE' in $HOME."
    ln -s $SCRIPT_DIR/$FILE ~/.$FILE
done
