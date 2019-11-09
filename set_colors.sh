#!/bin/bash

color_txt=`cat color_scheme.txt`
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
        colors[$color_idx]=$str
    fi
done

#for i in ${colors[@]}; do echo $i; done

## TERMITE
cp termite/config termite/config.old
termite_cfg=`cat termite/config.old`

for i in {0..15}
do
    termite_cfg=$(sed -r "s/^color$i=#([0-9]|[a-f])*/color$i=${colors[$i]}/g" <<< $termite_cfg) 
done

termite_cfg=$(sed -r "s/^foreground=#([0-9]|[a-f])*/foreground=${colors[16]}/g" <<< $termite_cfg) 
termite_cfg=$(sed -r "s/^background=#([0-9]|[a-f])*/background=${colors[17]}/g" <<< $termite_cfg) 
termite_cfg=$(sed -r "s/^cursor=#([0-9]|[a-f])*/cursor=${colors[16]}/g" <<< $termite_cfg) 

echo "$termite_cfg" > termite/config
xdotool key ctrl+shift+r # load new termite config by pressing ctrl+shift+r

