---
title: CMake for building C++ projects
description: This article shows how to use CMake to build a C++ project with implementation examples and explanations
author: hoan9x
date: 2024-10-13 12:00:00 +0700
categories: [CXX, CMake build system]
mermaid: true
---

> This article is not complete yet.
{: .prompt-warning }

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
# tree --dirsfirst cmake_demo_sample1
cmake_demo_sample1
|-- include
|   `-- playlist_manager.h
|-- src
|   `-- playlist_manager.cpp
|-- CMakeLists.txt
`-- main.cpp

2 directories, 4 files
```

```cmake
# Consider using a more recent version if newer features are required
cmake_minimum_required(VERSION 3.20)

# Define the project name
project(project_cpp_sample1)

# Use C++17 standard
set(CMAKE_CXX_STANDARD 17)  # Specifies the C++ standard to use
set(CMAKE_CXX_STANDARD_REQUIRED True)  # Ensures the specified standard is required

# Add the "include" directory to the search path for header files
include_directories(include)  # Includes header files located in the 'include' directory

# Add the main executable for the program
# We specify main.cpp as the main source file
# and src/playlist_manager.cpp as the source file containing the class definition
add_executable(${CMAKE_PROJECT_NAME}_exe 
    main.cpp  # Main entry point of the application
    src/playlist_manager.cpp  # Source file defining the PlaylistManager class
)

# Display a message when the project is configured successfully, including additional context
message(STATUS "Project ${CMAKE_PROJECT_NAME} has been configured successfully.")
message(STATUS "C++ Standard: ${CMAKE_CXX_STANDARD}")
```

```bash
root@988ac2e024bd:/workspaces/project_cpp_sample1# cmake -S . -B _build
-- The C compiler identification is GNU 11.4.0
-- The CXX compiler identification is GNU 11.4.0
-- Detecting C compiler ABI info
-- Detecting C compiler ABI info - done
-- Check for working C compiler: /usr/bin/cc - skipped
-- Detecting C compile features
-- Detecting C compile features - done
-- Detecting CXX compiler ABI info
-- Detecting CXX compiler ABI info - done
-- Check for working CXX compiler: /usr/bin/c++ - skipped
-- Detecting CXX compile features
-- Detecting CXX compile features - done
-- Project project_cpp_sample1 has been configured successfully.
-- C++ Standard: 17
-- Include directories: 
-- Compilation flags: 
-- Configuring done
-- Generating done
-- Build files have been written to: /workspaces/project_cpp_sample1/_build
root@988ac2e024bd:/workspaces/project_cpp_sample1# cmake --build _build 
[ 33%] Building CXX object CMakeFiles/project_cpp_sample1_exe.dir/main.cpp.o
[ 66%] Building CXX object CMakeFiles/project_cpp_sample1_exe.dir/src/playlist_manager.cpp.o
[100%] Linking CXX executable project_cpp_sample1_exe
[100%] Built target project_cpp_sample1_exe
root@988ac2e024bd:/workspaces/project_cpp_sample1# ./_build/project_cpp_sample1_exe 
Song A
Song B
```

```bash
# tree --dirsfirst cmake_demo_sample2
cmake_demo_sample2
|-- include
|   |-- playlist_manager.h
|   `-- user_manager.h
|-- lib
|   |-- PlaylistManager
|   |   |-- CMakeLists.txt
|   |   `-- playlist_manager.cpp
|   `-- UserManager
|       |-- CMakeLists.txt
|       `-- user_manager.cpp
|-- src
|   |-- CMakeLists.txt
|   `-- main.cpp
`-- CMakeLists.txt

5 directories, 9 files
```

Explanation of PUBLIC, PRIVATE and INTERFACE in CMake:
- In CMake, the keywords PUBLIC, PRIVATE, and INTERFACE are used in commands like `target_include_directories()`, `target_link_libraries()`, and similar to specify how certain properties (such as include directories or libraries) apply to the target itself and its consumers.
- PRIVATE:
  + The PRIVATE keyword means that the specified property (e.g include directories or libraries) is only used for the target itself. It does not propagate to other targets that link with the current target.
  + Use case: You use PRIVATE when you want to apply a setting or property only to the target being defined, without exposing it to targets that link to it.
  + Example: `target_include_directories(MyLibrary PRIVATE ${CMAKE_SOURCE_DIR}/include)` This means that the `MyLibrary` target will use the include directory `${CMAKE_SOURCE_DIR}/include`, but other targets that link with `MyLibrary` will not inherit this include path.
- PUBLIC:
  + The PUBLIC keyword means that the specified property is applied both to the target and any target that links to it. It propagates the property to dependent targets.
  + Use case: You use PUBLIC when you want both the current target and all consumers (targets that link with it) to have access to a property, like include directories or linked libraries.
  + Example: `target_include_directories(MyLibrary PUBLIC ${CMAKE_SOURCE_DIR}/include)` This means that both `MyLibrary` and any other target that links with `MyLibrary` will have access to the include directory `${CMAKE_SOURCE_DIR}/include`.
- INTERFACE:
  + The INTERFACE keyword is used when you want the property to be applied only to targets that link with the current target. It does not affect the target itself, but only propagates the property to consumers.
  + Use case: You use INTERFACE for things like header-only libraries, where no actual code or compiled object is needed for the current target, but consumers of the target need to be aware of certain properties (e.g include directories).
  + Example: `target_include_directories(MyInterfaceLibrary INTERFACE ${CMAKE_SOURCE_DIR}/include)` This means that only targets that link with `MyInterfaceLibrary` will inherit the include directory `${CMAKE_SOURCE_DIR}/include`, but `MyInterfaceLibrary` itself does not have an include directory since it is an interface.

Comparison of PUBLIC, PRIVATE, and INTERFACE:

|  **Keyword**  | **Affects the current target** | **Affects targets that link to the current target** |
| :-----------: | :----------------------------: | :-------------------------------------------------: |
|  **PRIVATE**  |              Yes               |                         No                          |
|  **PUBLIC**   |              Yes               |                         Yes                         |
| **INTERFACE** |               No               |                         Yes                         |

Summary:
- PRIVATE: The property is applied only to the current target.
- PUBLIC: The property is applied to both the current target and any target that links to it.
- INTERFACE: The property is applied only to targets that link to the current target, but not to the current target itself.

## 3. Building a C++ project as a library

Explanation of `include_directories()` vs `target_include_directories()`:
- `include_directories()`:
  + Global effect: The `include_directories()` command adds include directories globally for all targets in the current CMake scope. This means any target in the scope (including targets in subdirectories) will use the specified include directories.
  + Use case: It's typically used when you want to apply include directories globally to the entire project, not just to specific targets.
- `target_include_directories()`:
  + Target-specific effect: The `target_include_directories()` command allows you to specify include directories only for a specific target. This is a more modular and scalable approach, because it does not affect the entire project. The include directories are applied only to the target specified in the command, and can be propagated to other targets depending on whether you use the PUBLIC or PRIVATE keywords.
  + Use case: It’s preferred to use `target_include_directories()` when you want to control include directories per target and avoid unnecessary global scope changes. This makes the project more maintainable, especially in large projects.

## 4. Building a C++ project that uses third-party libraries

## 5. References

- [1] CMake Reference Documentation [Online]. Available: [link](https://cmake.org/cmake/help/latest/index.html).
- [2] CMake Tutorial [Online]. Available: [link](https://cmake.org/cmake/help/latest/guide/tutorial/index.html).
- [3] CMake FAQs [Online]. Available: [link](https://gitlab.kitware.com/cmake/community/-/wikis/FAQ).
- [4] Article. (2017, May. 11). *How to Build a CMake-Based Project* [Online]. Available: [link](https://preshing.com/20170511/how-to-build-a-cmake-based-project/).
- [5] Udemy Course. (2022). *Master CMake for Cross-Platform C++ Project Building* [Online]. Available: [link](https://www.udemy.com/course/master_cmake/).

[//]: # (----------SCOPE OF DECLARATION OF LIST OF IMAGES USED IN POST----------)
[img_1]: /assets/img/2024-10-CMake-for-building-Cpp-projects/01_cmake_simple_flowchart.png "CMake simple flowchart"
[img_1d]: /assets/img/2024-10-CMake-for-building-Cpp-projects/01d_cmake_simple_flowchart.png "CMake simple flowchart"
