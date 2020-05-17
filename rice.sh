#!/bin/bash
#
# Usage:
#   rice -h|--help
#   rice -t <tool> # set symbolic link to <tool> config if not set, restarts tool
#   rice           # interactive rice of all tools
#   rice -c [-f <file>] # set colors
#

DOTFILES=$HOME/Projects/dotfiles
INSTALLPATH=$HOME/.test

cd $DOTFILES # change this accordingly!

SCRIPTPATH=$(dirname "$(realpath -s "$0")") # from https://stackoverflow.com/questions/4774054/reliable-way-for-a-bash-script-to-get-the-full-path-to-itself

#CONFIGS=$(find . -type d | grep -v .git | tail -n +2 | cut -c 3-) # get config folder names (termite, i3, ...)

### Parse inputs
set_colors=1

### Get colors
color_txt=`cat $DOTFILES/color_scheme.txt`
colors=()

## Extract colors from text file in correct order
# Expects .Xresources-like definition of colors
color_idx=0
for str in $color_txt #extract colors 0-15, foreground and background
do
    if [[ $str =~ .*color.* ]]; then
        color_idx=$(echo $str | cut -d 'r' -f 2 | cut -d ':' -f 1)
    elif [[ $str =~ .*foreground.* ]] || [[ $str =~ .*cursorColor.* ]]; then
        color_idx=16
    elif [[ $str =~ .*background.* ]]; then
        color_idx=17
    elif [[ $str == *"#"* ]]; then
        str=$(echo "$str" | tr '[:lower:]' '[:upper:]')
        colors[$color_idx]=$str
    fi
done

### Create symlinks to configs if they don't exist
## .config setup
mkdir -p $INSTALLPATH
for dir in $DOTFILES/*/; do
    dir=${dir%*/} # remove trailing slash
    config=${dir##*/} # strip filename from path
    installdir=$INSTALLPATH/$config
    
    # normal setup: create symlink to installpath
    if [ ! -h "$installdir" ]; then
        if [ -d "$installdir" ]; then
            echo "Config directory $installdir already exists. Skipping..."
        else
            echo "Creating symlink $installdir -> $dir"
            ln -s $dir $INSTALLPATH/
        fi
    fi

    # additional setup: some tools need configs in ~
    if [ $config == 'X11' ]; then
        if [ ! -h "$HOME/.xinitrc" ]; then
            if [ -f "$HOME/.xinitrc" ]; then
                echo "Config file $HOME/.xinitrc already exists. Skipping..."
            else
                echo "Creating symlink $HOME/.xinitrc -> $dir/.xinitrc "
                ln -s $dir/.xinitrc $HOME/.xinitrc
            fi
        fi
    
        if [ ! -h "$HOME/.Xresources" ]; then
            if [ -f "$HOME/.Xresources" ]; then
                echo "Config file $HOME/.Xresources already exists. Skipping..."
            else
                echo "Creating symlink $HOME/.Xresources -> $dir/.Xresources"
                ln -s $dir/.Xresources $HOME/.Xresources
            fi
        fi
    fi

    # set colors
    if [ set_colors ]; then
        if [ $config == 'termite' ]; then
            echo "Setting termite colors"
            cp $dir/config /tmp/${config}_config.old
            cfg=`cat $dir/config`
            for i in {0..15}; do
                cfg=$(sed -r "s/^color$i=#([0-9]|[a-f]|[A-F])*/color$i=${colors[$i]}/g" <<< $cfg)
            done
            cfg=$(sed -r "s/^foreground=#([0-9]|[a-f]|[A-F])*/foreground=${colors[16]}/g" <<< $cfg) 
            cfg=$(sed -r "s/^background=#([0-9]|[a-f]|[A-F])*/background=${colors[17]}/g" <<< $cfg) 
            cfg=$(sed -r "s/^cursor=#([0-9]|[a-f]|[A-F])*/cursor=${colors[16]}/g" <<< $cfg) 
            echo "$cfg" > $dir/config
        elif [ $config == 'conky' ]; then
            echo "Setting conky colors"
            cp $dir/config /tmp/${config}_config.old
            cfg=`cat $dir/config`
            for i in {0..15}; do
                cfg=$(sed -r "s/^color$i *= *'#([0-9]|[a-f]|[A-F])*'/color$i = '${colors[$i]}'/g" <<< $cfg) 
            done
            echo "$cfg" > $dir/config
        elif [ $config == 'X11' ]; then
            echo "Setting Xresources colors"
            cp $dir/.Xresources /tmp/.Xresources.old
            cfg=`cat $dir/.Xresources`
            for i in {0..15}; do
                cfg=$(sed -r "s/^\*color$i: *#([0-9]|[a-f]|[A-F])*/\*.color$i: ${colors[$i]}/g" <<< $cfg)
            done
            cfg=$(sed -r "s/^\*foreground: *#([0-9]|[a-f]|[A-F])*/\*foreground: ${colors[16]}/g" <<< $cfg) 
            cfg=$(sed -r "s/^\*background: *#([0-9]|[a-f]|[A-F])*/\*background: ${colors[17]}/g" <<< $cfg) 
            cfg=$(sed -r "s/^\*cursorColor: *#([0-9]|[a-f]|[A-F])*/\*cursorColor: ${colors[16]}/g" <<< $cfg) 
            echo "$cfg" > $dir/.Xresources
        fi
    fi

    # reload new config when possible
    if [ -f "$dir/init.sh" ]; then
        echo "Restarting $config"
        $dir/init.sh
    fi
done
