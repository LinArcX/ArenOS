#!/bin/sh

# run the shell on a normal tty(tty1) instead of running it on: /dev/console.
shell_count=$(ps | awk '{print $4}' | grep 'login.sh$' | wc -l)

#echo $shell_count
#shell_count=$(ps | grep '/bin/init.sh$' | wc -l)

if [ $shell_count -eq 0 ]; then
  # Only one shell is active, execute a new shell
  setsid sh -c 'exec sh </dev/tty1 >/dev/tty1 2>&1'
  /bin/login.sh

  #echo "This is the last active shell. Starting a new one..."
  #/bin/sh
fi
