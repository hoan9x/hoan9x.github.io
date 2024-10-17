---
title: Bash scripting cheatsheet
description: This is a quick reference to Bash scripting
author: hoan9x
date: 2024-09-21 11:30:00 +0700
categories: [Linux, Bash]
---

[Bash scripting cheatsheet](https://devhints.io/bash)

## 1. Directory

### 1.1. Current directory

```bash
pwd_dir="$( cd "$( dirname "$0" )" && pwd )"
echo $pwd_dir
```

### 1.2. Searching

```bash
# Search directories based on prefix name
search_dir="/workspace"
target1=$(find ${search_dir} -maxdepth 1 -type d -name "PREFIX_*")
# Output of target1=('/workspace/PREFIX_ABC_012' '/workspace/PREFIX_ABC_051')
target2=$(find ${search_dir} -maxdepth 1 -type d -name "PREFIX_*" | sed 's!^.*/!!')
# Output of target2=('PREFIX_ABC_012' 'PREFIX_ABC_051')
```

### 1.3. Iteration

```bash
target=('PREFIX_ABC_012' 'PREFIX_ABC_051')
for item in $target; do
    echo "$item"
done
```

## 2. Options

### 2.1. Check options

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

## 3. Waiting script

### 3.1. Pause until user enters key

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

### 3.2. Sleep

```bash
sleep .5 # Waits 0.5 second.
sleep 5  # Waits 5 seconds.
sleep 5s # Waits 5 seconds.
sleep 5m # Waits 5 minutes.
sleep 5h # Waits 5 hours.
sleep 5d # Waits 5 days.
```

## 4. Logging function

### 4.1. Print color text

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

## 5. Filter and edit text

### 5.1. Filter multiple keywords

```bash
KEY1="key1"; KEY2="key2"; file_path="/tmp/file.txt"
grep "${KEY1}\|${KEY2}" ${file_path}
# or
egrep "${KEY1}|${KEY2}" ${file_path}
```

### 5.2. Edit lines in text file

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

## 6. File system

### 6.1. Wildcards

- `*` matches anything, regardless of length.

For example, the command `ls *.txt` will print all files with the extension `.txt`

- `?` matches anything, just for one place.

For example, the command `ls file?.txt` will print all files like `file1.txt`, `file2.txt`, `fileA.txt`, etc.

- `[]` matches just for one place, allows you to specify options.

For example, the command `ls file[0-9].txt` will print all files like `file1.txt`, `file2.txt`, etc. Only specify numbers 0-9.

### 6.2. Creating files and folders

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

### 6.3. File archiving and compression

- Compress file algorithm gzip: `tar -cvzf archive.tar.gz $file_to_compress`
- Compress file algorithm bzip2: `tar -cvjf archive.tar.bz2 $file_to_compress`
- Decompress file algorithm gzip: `tar -xvzf archive.tar.gz`
- Decompress file algorithm bzip2: `tar -xvjf archive.tar.bz2`

## 7. Check RAM, CPU, hard drive

### 7.1. Check RAM

The `meminfo` file inside the `/proc` pseudo-filesystem provides a usage report about memory on the system.
So you can use the `cat /proc/meminfo` command to read RAM/Swap information.
```bash
root@924886591cff:/workspaces# cat /proc/meminfo | grep Mem
MemTotal:        8007712 kB
MemFree:         5350452 kB
MemAvailable:    6102604 kB
root@924886591cff:/workspaces# cat /proc/meminfo | grep Swap
SwapCached:            0 kB
SwapTotal:       2097152 kB
SwapFree:        2097152 kB
```

Or use the `free` command, the `-h, --human` options will display human readable output.
```bash
root@924886591cff:/workspaces# free -h
               total        used        free      shared  buff/cache   available
Mem:           7.6Gi       1.5Gi       5.1Gi       3.0Mi       1.0Gi       5.9Gi
Swap:          2.0Gi          0B       2.0Gi
```

The `top` command can also display information about RAM/Swap in MiB (megabytes).
```bash
top - 15:33:06 up 51 min,  0 users,  load average: 0.24, 0.13, 0.10
Tasks:  17 total,   1 running,  16 sleeping,   0 stopped,   0 zombie
%Cpu(s):  3.4 us,  0.7 sy,  0.0 ni, 95.5 id,  0.0 wa,  0.0 hi,  0.4 si,  0.0 st
MiB Mem :   7820.0 total,   5244.4 free,   1559.1 used,   1016.5 buff/cache
MiB Swap:   2048.0 total,   2048.0 free,      0.0 used.   5977.4 avail Mem 
```

> You can use the [online converter](https://www.unitconverters.net/data-storage-converter.html) to quickly convert MB, GB, kB, etc.
{: .prompt-tip }

### 7.2. Check CPU

Use the command `cat /proc/cpuinfo` to display all CPU information, or use the following script to display only useful information:
```bash
#!/bin/bash
model=$(grep -m 1 'model name' /proc/cpuinfo | cut -d: -f2)
nb_cpu=$(grep 'physical id' /proc/cpuinfo | sort -u | wc -l)
nb_cores=$(grep 'cpu cores' /proc/cpuinfo | head -n 1 | cut -d: -f2)
nb_units=$(grep -c 'processor' /proc/cpuinfo)
echo "CPU model:${model}"
echo "${nb_cpu} CPU, ${nb_cores} physical cores per CPU, total ${nb_units} logical CPU units"
```

And here is an inline `awk` script:
```bash
root@924886591cff:/workspaces# cat /proc/cpuinfo | awk -F: '/^physical id/ { nb_cpu=$2>nb_cpu?$2:nb_cpu } \
  /^cpu cores/ { nb_cores=$2>nb_cores?$2:nb_cores } \
  /^processor/ { nb_units=$2>nb_units?$2:nb_units } \
  /^model name/ { model=$2 } \
  END { nb_cpu++; nb_units++; \
  print "CPU model:", model; \
  print nb_cpu, "CPU,", nb_cores, "physical cores per CPU, total", nb_units, "logical CPU units" }'
CPU model:  Intel(R) Core(TM) i5-8365U CPU @ 1.60GHz
1 CPU,  4 physical cores per CPU, total 8 logical CPU units
```

Or use the command `lscpu` to check cpu information like this:
```bash
root@924886591cff:/workspaces# lscpu
Architecture:            x86_64
  CPU op-mode(s):        32-bit, 64-bit
  Address sizes:         39 bits physical, 48 bits virtual
  Byte Order:            Little Endian
CPU(s):                  8
  On-line CPU(s) list:   0-7
Vendor ID:               GenuineIntel
  Model name:            Intel(R) Core(TM) i5-8365U CPU @ 1.60GHz
    CPU family:          6
    Model:               142
    Thread(s) per core:  2
    Core(s) per socket:  4
    Socket(s):           1
```

### 7.3. Check hard drive

Use the `df -h` command to show information about file system:
```bash
# Option -h, --human-readable will print sizes in powers of 1024 (e.g., 1023M)
root@924886591cff:/workspaces# df -h
Filesystem      Size  Used Avail Use% Mounted on
overlay        1007G   14G  943G   2% /
tmpfs            64M     0   64M   0% /dev
tmpfs           3.9G     0  3.9G   0% /sys/fs/cgroup
shm              64M     0   64M   0% /dev/shm
C:\             238G  144G   95G  61% /workspaces
/dev/sdd       1007G   14G  943G   2% /vscode
tmpfs           3.9G     0  3.9G   0% /proc/acpi
tmpfs           3.9G     0  3.9G   0% /sys/firmware
# Use additional <PATH/FILE> if you want to know the storage details of path/file.
root@924886591cff:/workspaces# df -h /workspaces/test.sh 
Filesystem      Size  Used Avail Use% Mounted on
C:\             238G  144G   95G  61% /workspaces
root@924886591cff:/workspaces# df -h /                   
Filesystem      Size  Used Avail Use% Mounted on
overlay        1007G   14G  943G   2% /
```

Use the `du -sh <FILE>` command to show the disk usage, option `-s, --summarize` will display only a total for each argument and option `-h, --human-readable` will print sizes in human readable format.
```bash
root@924886591cff:/workspaces# du -sh .           
12K     .
# Sort files in increasing capacity
root@924886591cff:/workspaces# du -sh /bin/* | sort -n
0       /bin/addr2line
0       /bin/ar
460K    /bin/x86_64-linux-gnu-as
908K    /bin/x86_64-linux-gnu-gcc-11
912K    /bin/x86_64-linux-gnu-g++-11
980K    /bin/openssl
```
