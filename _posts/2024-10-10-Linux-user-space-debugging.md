---
title: Linux user space debugging
description: This article demonstrates how to use GDB for debugging
author: hoan9x
date: 2024-10-10 19:00:00 +0700
categories: [Linux, GNU Debugger]
mermaid: true
---

## **What is GDB?**

---

GDB (GNU Debugger) is a debugging tool used to analyze and debug programs written in languages like C, C++, etc. It allows developers to see what happens inside their programs while they are running or what the program was doing at the moment it crashed. GDB is commonly used in the Linux/UNIX environment.

## **How to compile a program to use with GDB?**

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

```bash
root@dev:/GDB-learning# gdb ./simple.app 
# Launching GDB with a compiled program without the -g option will show an error
Reading symbols from ./simple.app...
(No debugging symbols found in ./simple.app)
(gdb) quit
root@dev:/GDB-learning# gdb ./simple_debug.app 
# And here is launching GDB with a compiled program with -g option
Reading symbols from ./simple_debug.app...
(gdb) q
root@dev:/GDB-learning# gdb
# Another way to load a compiled program into GDB
(gdb) file ./simple_debug.app 
Reading symbols from ./simple_debug.app...
(gdb) 
```

There are 2 ways to launch GDB with a compiled program:
- Use command `gdb <executable_path>`.
- Start `gdb` first, then use command `file <executable_path>`.

> This article is not complete yet.
{: .prompt-warning }
