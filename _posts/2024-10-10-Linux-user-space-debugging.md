---
title: Linux user space debugging
description: This article demonstrates how to use GDB for debugging
author: hoan9x
date: 2024-10-10 19:00:00 +0700
categories: [Linux, GNU Debugger]
mermaid: true
---

> This article is not complete yet.
{: .prompt-warning }

## 1. What is GDB?

GDB (GNU Debugger) is a debugging tool used to analyze and debug programs written in languages like C, C++, etc. It allows developers to see what happens inside their programs while they are running or what the program was doing at the moment it crashed. GDB is commonly used in the Linux/UNIX environment.

## 2. How to compile a program to use with GDB?

To use the debugger, you must compile your program with the `-g` option.

```bash
root@dev:/GDB-learning# gcc -o simple.app main.c
root@dev:/GDB-learning# gcc -o simple_debug.app main.c -g
# Check file size
root@dev:/GDB-learning# ls -l simple.app 
-rwxr-xr-x 1 root root 15960 Oct 13 06:03 simple.app
root@dev:/GDB-learning# ls -l simple_debug.app 
-rwxr-xr-x 1 root root 17136 Oct 13 06:04 simple_debug.app
```

The -g option tells the compiler to store additional debugging information. You can see the executable file size with `-g` option is larger than without `-g` option (**17136>15960** bytes).

## 3. GDB basic commands

### 3.1. Start/Stop the debugger

Type `gdb` to start the debugger, to not print the version number on startup, type `gdb -q` (or `--quiet`,`--silent`).<br>
In the GDB command console, type `q` (or `quit`, `exit`) to stop GDB command.<br>
You can type `help <command>` to read instructions on using the commands.

![Desktop View][img_1]{: width="800" height="420" .normal }

### 3.2. Start GDB with a compiled program

There are 2 ways to start GDB with a compiled program:
- Use command `gdb <executable_path>`.
- Start `gdb` first, then use command `file <executable_path>`.

```bash
# Launching GDB with a compiled program without the -g option will show an error
root@dev:/GDB-learning# gdb ./simple.app 
Reading symbols from ./simple.app...
(No debugging symbols found in ./simple.app)
# And here is launching GDB with a compiled program with -g option
root@dev:/GDB-learning# gdb ./simple_debug.app 
Reading symbols from ./simple_debug.app...
# Another way to load a compiled program into GDB
root@dev:/GDB-learning# gdb
(gdb) file ./simple_debug.app 
Reading symbols from ./simple_debug.app...
```

## 4. References

- [1] Paul Deitel and Harvey Deitel, "Using the GNU C++ Debugger" in *C++ How to Program*, 8th Edition, 2012.
- [2] Udemy Course. (2020). *Learn Linux User Space Debugging* [Online]. Available: [link](https://www.udemy.com/course/learn-linux-user-space-debugging/)

[//]: # (----------SCOPE OF DECLARATION OF LIST OF IMAGES USED IN POST----------)
[img_1]: /assets/img/2024-10-Linux-user-space-debugging/01_start_stop_gdb.gif "Start/Stop GDB"
