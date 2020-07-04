#!/bin/bash

echo "Ricing termite..."
colors=("$@")
cfg=$(cat config)

for i in {0..15}; do
  cfg=$(sed -r "s/^color$i=#([0-9]|[a-f]|[A-F])*/color$i=${colors[$i]}/g" <<< "$cfg")
done
cfg=$(sed -r "s/^foreground=#([0-9]|[a-f]|[A-F])*/foreground=${colors[16]}/g" <<< "$cfg")
cfg=$(sed -r "s/^background=#([0-9]|[a-f]|[A-F])*/background=${colors[17]}/g" <<< "$cfg")
cfg=$(sed -r "s/^cursor=#([0-9]|[a-f]|[A-F])*/cursor=${colors[16]}/g" <<< "$cfg")
echo "$cfg" > config
