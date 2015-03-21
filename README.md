# Dotfiles

## Overview

## Install this repo

    $ git clone https://github.com/parkerkane/dotfiles.git .dotfiles
    $ ./.dotfiles/ohmy-install.sh
    $ ./.dotfiles/bin/dfm install # creates symlinks to install files

## Install powerline fonts

    $ git clone https://github.com/powerline/fonts.git
    $ cd fonts
    $ ./install.sh
    
Remember to change font in iTerm.

    Preferences > Profiles > Default (or other profile) > Text
    
    Regular Font & Non-ASCII font

## Custom hostname and identify production servers

Theme loads custom boxname from `~/.box-name` or `/etc/box-name` file.

Also if name starts with dollar `$` symbol it will change color to alternative. This is for identify production servers.

## Commit

    $ dfm add .
    $ dfm commit -m "...."
    $ dfm push

## Update

    $ dfm umi # update-merge-install

## Full documentation

For more information, check out the [wiki](http://github.com/justone/dotfiles/wiki).

You can also run <tt>dfm --help</tt>.
