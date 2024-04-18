#!/bin/sh

notice "Generating a new SSH key for GitHub..."

# Create a directory for SSH keys if it doesn't exist
mkdir -p ~/.ssh

# Generating a new SSH key
# https://docs.github.com/en/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent#generating-a-new-ssh-key
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -C "$1"
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -C "$1"

# Adding your SSH key to the ssh-agent
# https://docs.github.com/en/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent#adding-your-ssh-key-to-the-ssh-agent
eval "$(ssh-agent -s)"

touch ~/.ssh/config
echo "Host *\n    AddKeysToAgent yes\n    UseKeychain yes\n    IdentitiesOnly yes\n    IdentityFile ~/.ssh/id_ed25519\n    IdentityFile ~/.ssh/id_rsa" | tee ~/.ssh/config

ssh-add --apple-use-keychain ~/.ssh/id_ed25519
ssh-add --apple-use-keychain ~/.ssh/id_rsa

# Adding your SSH key to your GitHub account
# https://docs.github.com/en/github/authenticating-to-github/adding-a-new-ssh-key-to-your-github-account
notice "run 'pbcopy < ~/.ssh/id_ed25519.pub' and paste that into GitHub"
