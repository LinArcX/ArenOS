# ArenOS
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
- There is just one user. 
  - So you won't find utilities like: useradd, userdel, usermod
- There is no concept of groups.
- You need two passwords: 1. login password. 2. `exed` password(execute/edit)
  - with login password, you can just login to the system.
  - but for executing binaries in `/bin` or editiing files in `/etc`, you need an `exed` password.
    - Imagine a hackers can succesfully login to your system. so he can execute anything or edit any files. because of that, we added extra security layer.
- Even with these security guards, some operations still should not be happen. like: `rm -rfd /`
  - These problems should handle by user applications.(in this case rm should not allow users to delete /)
  - By all these guards, still people can install random software that they don't know how they works. We strongly encourage you to just install the software that you read their source code and fully understand them.
    - In this way, you are the protector of your system. not third-party companies, applications.
- More compact FileSystem Hierarchy. ArenOS includes:
  - /bin:  all binaries goes here.
  - /boot: specific for kernel and any configuration related to it.
  - /dev:  device files representing hardware devices, including terminals, disk drives, and others
  - /etc:  configurations of the binaries in /bin resides here.
  - /home: directory for keeping all personal stuff of the user.
  - /mnt:  mount point for mounting file systems and removable media such as USB drives.
  - /proc: virtual file system that provides information about processes and the kernel.
  - /sys:  virtual file system exposing kernel and hardware information.
  - /tmp:  directory for temporary files that are usually cleared on system reboot.(by default 1GB)
  - /var:  variable files such as logs, spool files, and temporary files.(by default 2GB)

  There is no:
  - /lib and /lib64: since all applications compiled statically. in this way, people forced to include source codes into their application and recompile them.
  - /media: you can mount your removable media in /mnt.
  - /opt: you can put your software in /home/software
  - /root: you are the root and your home directory is home!
  - /run: ?
  - /sbin and /usr: /bin is enough.
  - /srv: ?

- There is no [package manager](./docs/PackageManagers.txt)

## License
![License](https://img.shields.io/github/license/LinArcX/ArenOS.svg?style=flat-square)
