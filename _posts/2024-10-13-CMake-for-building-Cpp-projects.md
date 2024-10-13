---
title: CMake for building C++ projects
description: This article demonstrates how to use GDB for debugging
author: hoan9x
date: 2024-10-13 12:00:00 +0700
categories: [Cpp, CMake build system]
mermaid: true
---

## **Introduction**

### **How to compile a simple C/C++ project?**

---

To build (compile) a simple C/C++ project, using GCC is sufficient. GCC (GNU Compiler Collection) is a compiler system produced by the GNU Project that compiles various programming languages, including C and C++. The gcc command is used to compile C code, while the g++ command, which is part of GCC, is specifically designed for compiling C++ code. GCC (with gcc for C and g++ for C++) is the most widely used compiler system in Unix-based systems.

```bash
# Compile C code with "gcc -o <executable_file_name> <file_c_to_compile>"
gcc -o my_c_program my_program.c
# Compile C++ code with "g++ -o <executable_file_name> <file_cpp_to_compile>"
g++ -o my_cpp_program my_program.cpp
```

Note that besides GCC, there are many other compilers, such as Clang, Intel C++ Compiler (ICC), TinyCC (TCC), etc. While GCC can compile multi-file projects, it requires multiple steps, such as compiling source files into object files, linking directories, etc. Therefore, it's often useful to use an automated tool, like Make or CMake, to streamline and shorten the build process.

### **What is Make/CMake?**

Make is a tool that automates the process of compiling source code, making it easier and faster to build complex projects. The compilation instructions are stored in a `Makefile`, which Make uses to build the project. However, as projects grow in complexity, the `Makefile` can become difficult to manage. To address this, CMake was developed.

CMake automatically generates a `Makefile` that Make can use to compile the project. For each project, the configuration for CMake is stored in a `CMakeLists.txt` file.

> This article is not complete yet.
{: .prompt-warning }
