#!/usr/bin/env bash

### Launch Polybar

## Files and Directories
DIR="$HOME/.config/polybar"
SFILE="$DIR/system"
RFILE="$DIR/.system"
MFILE="$DIR/.module"

## Launch Polybar with selected style
launch_bar() {
  if [[ ! `pidof polybar` ]]; then
    ## Launch polybar on each monitor
    polybar -q main -c "$DIR"/config &
  else
    polybar-msg cmd restart
  fi
}

# Execute the functions
launch_bar
