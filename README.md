# ArenOs
A minimal os based on busybox. it made with scc and musl and consists of:
- sbase/ubase
- sinit
- monocypher


# Design decisions
- There is just one user. yes you are the ROOT! (no need for sudo, useradd, userdel, usermod, etc..)
- There is no concept of permission. (You are the owner of your computer, why you need to request with sude every fucking time?)
- Security concerns should handle by userspace applications/kernel.(not by creating permissions, groups.)
- There is no traditional file hierarchy.
  - 

## Considerations
- exit is part of the shell, so you need ro rerun the login program when you get out of your shell.

## License
![License](https://img.shields.io/github/license/LinArcX/ArenOs.svg?style=flat-square)
