---
title: Bash scripting cheatsheet
description: This is a quick reference to Bash scripting
author: hoan9x
date: 2024-09-21 11:30:00 +0700
categories: [Linux, Bash]
---

## Reference link

<https://devhints.io/bash>

## Directory

### Current directory

```bash
pwd_dir="$( cd "$( dirname "$0" )" && pwd )"
echo $pwd_dir
```

### Searching

```bash
# Search directories based on prefix name
search_dir="/workspace"
target1=$(find ${search_dir} -maxdepth 1 -type d -name "PREFIX_*")
# Output of target1=('/workspace/PREFIX_ABC_012' '/workspace/PREFIX_ABC_051')
target2=$(find ${search_dir} -maxdepth 1 -type d -name "PREFIX_*" | sed 's!^.*/!!')
# Output of target2=('PREFIX_ABC_012' 'PREFIX_ABC_051')
```

### Iteration

```bash
target=('PREFIX_ABC_012' 'PREFIX_ABC_051')
for item in $target; do
    echo "$item"
done
```

## Options

### Check options

```bash
#!/bin/bash

function show_usage {
    printf "Usage: $0 [options [parameters]]\n"
    printf "Options:\n"
    printf "-s, xxx (Default: 'xxx')\n"
    printf "-h|--help, print help section\n"
    printf "Example: bash this.sh -s value_s\n"
    return 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
    -s)
        VALUE_S=$2
        shift
        ;;
    --help|-h)
        show_usage
        exit 0
        ;;
    *)
        echo "Invalid option: $1"
        exit 1
        ;;
    esac
    shift
done

if [ "$VALUE_S" = "compare string" ]; then
    echo "xxx"
else
    echo "xxx"
fi
```

## Waiting script

### Pause until user enters key

```bash
while [ true ] ; do
read -n 1 -p "Input Selection (y/n):" myinput
if [ "y" = ${myinput} ]; then
    printf "\nSelec y\n"
    exit;
elif [ "n" = ${myinput} ]; then
    printf "\nSelec n\n"
    exit;
else
    printf "\nInvalid choose\n"
fi
done
```

### Sleep

```bash
sleep .5 # Waits 0.5 second.
sleep 5  # Waits 5 seconds.
sleep 5s # Waits 5 seconds.
sleep 5m # Waits 5 minutes.
sleep 5h # Waits 5 hours.
sleep 5d # Waits 5 days.
```

## Logging function

### Print color text

```bash
#!/bin/bash

function log () {
    type=$1
    message=$2
# declare -A defines an associative array
    declare -A colors=(\
        ["red"]="\e[31m"\
        ["green"]="\033[32m"\
        ["yellow"]="\e[33m"\
        ["blue"]="\x1B[34m"\
        # ["magenta"]="\e[35m"\
        # ["cyan"]="\e[36m"\
        # ["white"]="\e[37m"\
    );
    end="\e[m"
# The -e option of the echo command enable the parsing of the escape sequences.
# The "\e[0m" sequence removes all attributes (formatting and colors), add it at the end of each colored text.
# The "\e" or "\003" or "\x1B" is the <Esc> character.
    if [ "${type}" = "error" ]; then
        echo -e ${colors["red"]}"[ERROR] "${message}${end}
    elif [ "${type}" = "success" ]; then
        echo -e ${colors["green"]}"[SUCCESS] "${message}${end}
    elif [ "${type}" = "warning" ]; then
        echo -e ${colors["yellow"]}"[WARN] "${message}${end}
    elif [ "${type}" = "info" ]; then
        echo -e ${colors["blue"]}"[INFO] "${message}${end}
    else
        log error "Function usage: log <error/success/warning/info> \"message\""
}

log error   "This is error log"
log success "This is success log"
log warning "This is warning log"
log info    "This is info log"
log xxx     "This line will not be printed"
```

## Filter and edit text

### Filter multiple keywords

```bash
KEY1="key1"; KEY2="key2"; file_path="/tmp/file.txt"
grep "${KEY1}\|${KEY2}" ${file_path}
# or
egrep "${KEY1}|${KEY2}" ${file_path}
```

### Edit lines in text file

```bash
KEY_1="key1="; KEY_2="key2="; NEW_VALUE_1="test/aaa"; NEW_VALUE_2="test/ccc"
file_to_change="/tmp/file.txt"

sed -i -e "/${KEY_1}/c\\${KEY_1}${NEW_VALUE_1}" \
-e "/${KEY_2}/c\\${KEY_2}${NEW_VALUE_2}" ${file_to_change}

<<Comment
- Example file before change:
key1=aaa
key2=bbb
- Example file after change:
key1=test/aaa
key2=test/ccc
Comment
```

## File system

### Wildcards

- `*` matches anything, regardless of length.

For example, the command `ls *.txt` will print all files with the extension `.txt`

- `?` matches anything, just for one place.

For example, the command `ls file?.txt` will print all files like `file1.txt`, `file2.txt`, `fileA.txt`, etc.

- `[]` matches just for one place, allows you to specify options.

For example, the command `ls file[0-9].txt` will print all files like `file1.txt`, `file2.txt`, etc. Only specify numbers 0-9.

### Creating files and folders

- Create multiple files and folders using `{}`, it's like a multiplication.

```bash
mkdir {TEST1,TEST2}_{01,02}
# Output like "TEST1_01  TEST1_02  TEST2_01  TEST2_02"
touch {file_a,file_b}_{1..3}.txt
# Output like "file_a_1.txt  file_a_2.txt  file_a_3.txt  file_b_1.txt  file_b_2.txt  file_b_3.txt"
touch {x,y}{_1,_2}.txt
# Output like "x_1.txt  x_2.txt  y_1.txt  y_2.txt"
touch file{1..100}.txt
# Output like "file1.txt  file2.txt  ...  file100.txt"
```

### File archiving and compression

- Compress file algorithm gzip: `tar -cvzf archive.tar.gz $file_to_compress`
- Compress file algorithm bzip2: `tar -cvjf archive.tar.bz2 $file_to_compress`
- Decompress file algorithm gzip: `tar -xvzf archive.tar.gz`
- Decompress file algorithm bzip2: `tar -xvjf archive.tar.bz2`
