# ArenOs
A minimal linux distribution based on suckless/openbsd/busybox ideas. it consists of:
- us: user-space applications including:
  init, login, lastlog, cat, etc..
- ks: linux kernel.
- cryptography: monocypher.

# How to build?
You can use `scc` as the c compiler and `musl` as c lib. there is a `build.sh` in the root of the project. just:
```
chmod +x build.sh
./build.sh
```

# Design decisions
- There is just one user. yes you are the ROOT! (no need for sudo, useradd, userdel, usermod, etc..)
- There is no concept of permission. (You are the owner of your computer, why you need to request with sude every fucking time?)
- Security concerns should handle by userspace applications/kernel.(not by creating permissions, groups.)
  - For instance: `rm -rf /` is a security issue related to `rm` command. each application is responsible to create himself as safe and secure as possible.
  - One of the consequences is that
- There is no traditional file hierarchy. just these directories exists:
  - /dev
  - /info
  - /mnt
  - /pkgs
  - /proc
  - /sys
  - /tmp

- All applications(including kernel) will goes into /pkgs. there is no /bin, /sbin/, /run.
  - Each application will responsible to maintains his own configurations inside. (so no need for /etc)
  - There is no /lib directory. if you want to use a library, you should refer to it's package in /pkg.

- There is no package manager.
  - package managers makes easy to people to be lazy and install any kind of software without knowing how they works. ArenOS encourage you to first know exactly what is the software is doing. if you have
  1% uncertantity, you should not install that package on your machine. if you want to experiment with that, you can run it in a isolated(sandboxed) environment.

## License
![License](https://img.shields.io/github/license/LinArcX/ArenOs.svg?style=flat-square)
