#!/bin/sh

while true; do
  echo -n "User: "
  read username
  echo -n "Password: "
  read -s password

  if [ "$username" = "root" ] && [ "$password" = "toor" ]; then
    echo "Welcome, $username!"
    setsid sh -c 'exec sh </dev/tty1 >/dev/tty1 2>&1'

    initsh_count=$(ps | awk '{print $4}' | grep '^init.sh$' | wc -l)
    if [ $initsh_count -eq 0 ]; then
      /bin/init.sh
    fi
 
    break
  else
    echo "Login incorrect"
  fi
done



## Continuously monitor the number of shell instances
#while true; do
#  shell_count=$(ps | grep 'sh$' | wc -l)
#
#  if [ $shell_count -eq 1 ]; then
#    # Only one shell is active, execute a new shell
#    echo "This is the last active shell. Starting a new one..."
#    /bin/sh
#  fi
#done
#
    #setsid sh -c 'exec sh </dev/tty1 >/dev/tty1 2>&1'
    #exec sh
