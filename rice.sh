#!/bin/bash
#
# Usage:
#   rice -h|--help
#   rice -t <tool> # set symbolic link to <tool> config if not set, restarts tool
#   rice           # interactive rice of all tools
#   rice -c [-f <file>] # set colors
#
#
# color formats
#  - termite
#     [colors]
#     background=#1D1F21
#     color0=#28223D ...
#  - conky
#     background='#1D1F21'
#     color0='#28223D' ...
#  - Xresources
#     *background:#1D1F21
#     *.color0:#28223d
#  - i3, polybar: load Xresources
#

DOTFILES=$HOME/Projects/dotfiles
INSTALLPATH=$HOME/.config

cd $DOTFILES # change this accordingly!

#SCRIPTPATH=$(dirname "$(realpath -s "$0")") # from https://stackoverflow.com/questions/4774054/reliable-way-for-a-bash-script-to-get-the-full-path-to-itself

### Parse inputs
tools=()
set_colors=0
while [[ $# -gt 0 ]]; do
key="$1"

case $key in
    -t|--tool)
      tools+=("$2")
      shift # past argument
      shift # past value
    ;;
    -c|--colors)
      set_colors=1
      shift # past argument
    ;;
    *)    # unknown option
      shift # past argument
    ;;
esac
done

if [ ${#tools[@]} -eq 0 ]; then
  # Ugly workaround to get list of all tools:
  #   1) read directories to all tools into tools_temp
  #   2) iterate over them and strip em down to tool name

  #tools=$(find . -type d | grep -v .git | tail -n +2 | cut -c 3-)
  tools_temp=("$DOTFILES"/*)
  for dir in "${tools_temp[@]}"; do
    if [ -d "$dir" ]; then
      dir=${dir%*/}
      tool="${dir##*/}"
      if [ "$tool" == "X11" ]; then
        tools=("$tool" "${tools[@]}") # X11 should be processed first (so XResources changes propagate to other tools later)
      else
        tools+=("$tool")
      fi
    fi
  done
fi

### Helper functions
create_symlink() {
  if [ ! -h "$2" ]; then
    if [ -f "$2" ]; then
      echo "Config file $2 already exists. Skipping..."
    else
      echo "Creating symlink $1 -> $2"
      ln -s "$1" "$2"
    fi
  fi
}

### Set colors
colors=()
if [ $set_colors == 1 ]; then
  echo "Getting colors..."
  ### Get colors
  color_txt=$(cat "color_scheme.txt")

  ## Extract colors from text file in correct order
  # Expects .Xresources-like definition of colors
  color_idx=0
  for str in $color_txt #extract colors 0-15, foreground and background
  do
    if [[ $str =~ .*color.* ]]; then
      color_idx=$(echo "$str" | cut -d 'r' -f 2 | cut -d ':' -f 1)
    elif [[ $str =~ .*foreground.* ]] || [[ $str =~ .*cursorColor.* ]]; then
      color_idx=16
    elif [[ $str =~ .*background.* ]]; then
      color_idx=17
    elif [[ $str == *"#"* ]]; then
      str=$(echo "$str" | tr '[:lower:]' '[:upper:]')
      colors[$color_idx]=$str
    fi
  done
fi

### Create symlinks to configs if they don't exist
mkdir -p "$INSTALLPATH"
for config in "${tools[@]}"; do
  dir="$DOTFILES"/"$config"
  installdir="$INSTALLPATH"/"$config"

  #echo "dir = $dir"
  #echo "config = $config"
  #echo "installdir = $installdir"

  # set colors
  if [ $set_colors == 1 ] && [ -f "$dir"/rice_colors.sh ]; then
    cd "$dir" && ./rice_colors.sh "${colors[@]}" && cd ..
  fi

  # normal setup: create symlink to installpath
  create_symlink "$dir" "$installdir"

  # additional setup for special snowflakes
  if [ $config == 'X11' ]; then
    create_symlink "$dir"/.xinitrc "$HOME"/.xinitrc
    create_symlink "$dir"/.Xresources "$HOME"/.Xresources
  fi

  # reload new config when possible
  if [ -f "$dir/init.sh" ]; then
    echo "Initializing $config..."
    "$dir"/init.sh &
  fi
done

