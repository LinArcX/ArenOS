#!/bin/sh

# Continuously monitor the number of shell instances
while true; do
  shell_count=$(ps | grep 'sh$' | wc -l)

  if [ $shell_count -eq 1 ]; then
    # Only one shell is active, execute a new shell
    echo "This is the last active shell. Starting a new one..."
    /bin/sh
  fi
done
