#!/bin/bash

echo "Linking config files..."
this_dir=$(dirname $(realpath $0))
home_dir=$(realpath ~)
ln -s "$this_dir/config/hypr" "$home_dir/.config/hypr"
ln -s "$this_dir/quickshell" "$home_dir/.config/quickshell"

