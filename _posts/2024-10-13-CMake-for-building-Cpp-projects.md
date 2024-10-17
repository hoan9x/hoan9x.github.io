---
title: CMake for building C++ projects
description: This article shows how to use CMake to build a C++ project by performing the exercises
author: hoan9x
date: 2024-10-13 12:00:00 +0700
categories: [Cpp, CMake build system]
mermaid: true
---

## 1. Introduction

### 1.1. How to compile a simple C/C++ project?

To build (compile) a simple C/C++ project, using GCC is sufficient. GCC (GNU Compiler Collection) is a compiler system produced by the GNU Project that compiles various programming languages, including C and C++. The `gcc` command is used to compile C code, while the `g++` command, which is part of GCC, is specifically designed for compiling C++ code. GCC (with `gcc` for C and `g++` for C++) is the most widely used compiler system in Unix-based systems.

```bash
# Compile C code with "gcc -o <executable_file_name> <file_c_to_compile>"
gcc -o my_c_program my_program.c
# Compile C++ code with "g++ -o <executable_file_name> <file_cpp_to_compile>"
g++ -o my_cpp_program my_program.cpp
```

Note that besides GCC, there are many other compilers, such as Clang, Intel C++ Compiler (ICC), TinyCC (TCC), etc. While GCC can compile multi-file projects, it requires multiple steps, such as compiling source files into object files, linking directories, etc. Therefore, it's often useful to use an automated tool, like Make or CMake, to streamline and shorten the build process.

### 1.2. What is Make/CMake?

Make is a tool that automates the process of compiling source code, making it easier and faster to build complex projects. The compilation instructions are stored in a `Makefile`, which Make uses to build the project. However, as projects grow in complexity, the `Makefile` can become difficult to manage. To solve this, CMake (Cross-platform Make) was developed.

![light mode only][img_1]{: width="385" height="359" .light }
![dark mode only][img_1d]{: width="385" height="359" .dark }

CMake automatically generates a `Makefile` that Make can use to compile the project. For each project, the configuration for CMake is stored in a `CMakeLists.txt` file.

## 2. Building a C++ project

### 2.1. Project layout

```bash
# tree --dirsfirst project_cpp_simple
/ project_cpp_simple/ 
├── include 
│   └── playlist_manager.h 
├── src 
│   └── playlist_manager.cpp 
├── CMakeLists.txt 
└── main.cpp

2 directories, 4 files
```

## 3. Building a C++ project as a library

## 4. Building a C++ project that uses third-party libraries

## 5. References

- [1] CMake Reference Documentation [Online]. Available: [link](https://cmake.org/cmake/help/latest/index.html).
- [2] CMake Tutorial [Online]. Available: [link](https://cmake.org/cmake/help/latest/guide/tutorial/index.html).
- [3] CMake FAQs [Online]. Available: [link](https://gitlab.kitware.com/cmake/community/-/wikis/FAQ).
- [4] Article. (2017, May. 11). *How to Build a CMake-Based Project* [Online]. Available: [link](https://preshing.com/20170511/how-to-build-a-cmake-based-project/).
- [5] Udemy Course. (2022). *Master CMake for Cross-Platform C++ Project Building* [Online]. Available: [link](https://www.udemy.com/course/master_cmake/).

> This article is not complete yet.
{: .prompt-warning }

[//]: # (----------SCOPE OF DECLARATION OF LIST OF IMAGES USED IN POST----------)
[img_1]: /assets/img/2024-10-CMake-for-building-Cpp-projects/01_cmake_simple_flowchart.png "CMake simple flowchart"
[img_1d]: /assets/img/2024-10-CMake-for-building-Cpp-projects/01d_cmake_simple_flowchart.png "CMake simple flowchart"
