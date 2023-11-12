# Compile it
  gcc -o rakhsh rakhsh.c -static

# Run it in isolated environment
  sudo chroot . ./rakhsh
