#!/bin/bash

echo "Ricing conky..."
colors=("$@")
cfg=$(cat config)

for i in {0..15}; do
  cfg=$(sed -r "s/^color$i *= *'#([0-9]|[a-f]|[A-F])*'/color$i = '${colors[$i]}'/g" <<< $cfg)
done
echo "$cfg" > config
