---
title: Quy trình biên dịch một chương trình C/C++
description: Bài viết này nói về quá trình compiler, assembler, linker và loader một chương trình C/C++
author: hoan9x
date: 2024-12-26 16:00:00 +0700
categories: [CXX, Building process]
mermaid: true
---

> Bài viết này vẫn chưa hoàn thiện.
{: .prompt-warning }

Bài viết này giải thích quá trình preprocess, compile, link, và load một chương trình C/C++ với GCC (GNU Compiler Collection). Mục tiêu: Hiểu các quy trình liên quan đến preprocess, compile, link, load và chạy chương trình C/C++.

## 1. Compiler, assembler và linker

Quá trình xây dựng chương trình C/C++ bao gồm bốn giai đoạn: preprocessing, compiling, assembling, và linking.

- Preprocessing: Xử lý các tệp include, chỉ thị biên dịch có điều kiện và macros.
- Compiling: Nó nhận các output từ preprocessor sau đó chuyển mã nguồn thành mã assembler.
- Assembling: Chuyển mã assembler thành tệp đối tượng.
- Linking: Kết hợp các tệp đối tượng và thư viện để tạo ra tệp thực thi duy nhất.

Trong UNIX/Linux, tệp thực thi (executable file) không có phần mở rộng (file extension). Còn trong Windows, các tệp thực thi có thể có phần mở rộng như `.exe`, `.com` và `.dll`. Bảng dưới liệt kê file extension tương ứng với các giai đoạn biên dịch được thực hiện với GCC.

| File extension                                                                                             | Mô tả                                                                                                                                    |
| ---------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| `file_name.c`                                                                                              | Mã nguồn C cần được **preprocess**.                                                                                                      |
| `file_name.i`                                                                                              | Mã nguồn C không cần **preprocess**.                                                                                                     |
| `file_name.ii`                                                                                             | Mã nguồn C++ không cần **preprocess**.                                                                                                   |
| `file_name.h`                                                                                              | Tệp tiêu đề C (không được **compile** hoặc **link**).                                                                                    |
| `file_name.cc`<br>`file_name.cp`<br>`file_name.cxx`<br>`file_name.cpp`<br>`file_name.c++`<br>`file_name.C` | Mã nguồn C++ cần được **preprocess**.<br>Chú ý với `file_name.cxx`, "xx" phải là hai ký tự "x".<br>Và `file_name.C` có chữ "C" viết hoa. |
| `file_name.s`                                                                                              | Mã **assembler**.                                                                                                                        |
| `file_name.S`                                                                                              | Mã **assembler** cần được **preprocess**.                                                                                                |
| `file_name.o`                                                                                              | Tệp đối tượng.                                                                                                                           |

Hình sau đây hiển thị các bước liên quan đến quá trình xây dựng chương trình C/C++:

![light mode only][img_1]{: width="659" height="560" .light }
![dark mode only][img_1d]{: width="659" height="560" .dark }

## 2. Object files và executable files

Sau khi trải qua bước assembler, mã nguồn biến thành các object files (ví dụ: `file.o`, `file.obj`) rồi nó tiếp tục được linker để tạo executable.

Object files và executable có nhiều định dạng ví dụ như:
- ELF (Executable and Linking Format): Được sử dụng trên hệ thống Linux.
- COFF (Common Object-File Format): Được sử dụng trên hệ thống Windows.

Bảng sau liệt kê một số định dạng object file:

| **Định dạng** | **Mô tả**                                                                                                                                                                                                                                                                                                           |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **a.out**     | Định dạng `a.out` là định dạng tệp ban đầu cho Unix.<br>Gồm 3 sections: `text` (program code), `data` (initialized data), và `bss` (uninitialized data).<br>Định dạng này không có hỗ trợ gỡ lỗi ngoại trừ `stabs` (một định dạng để lưu trữ thông tin gỡ lỗi).                                                     |
| **COFF**      | Định dạng COFF được giới thiệu cùng với System V Release 3 (SVR3) Unix,<br>nó hỗ trợ gỡ lỗi hạn chế.                                                                                                                                                                                                                |
| **ECOFF**     | Định dạng ECOFF (Extended COFF) là biến thể của COFF, dành cho các máy trạm MIPS và Alpha.                                                                                                                                                                                                                          |
| **XCOFF**     | Định dạng XCOFF (eXtended COFF) cũng là biến thể của COFF,<br>dành cho IBM AIX (là hệ điều hành Unix của IBM).                                                                                                                                                                                                      |
| **PE**        | Định dạng PE (Portable Executable) được sử dụng trên Windows,<br>mở rộng từ COFF thường có extension đuôi `.exe`.                                                                                                                                                                                                   |
| **ELF**       | Định dạng ELF ra đời cùng với System V Release 4 (SVR4) Unix.<br>ELF tương tự COFF ở chỗ được tổ chức thành nhiều sections, nhưng loại bỏ nhiều hạn chế của COFF.<br>ELF được sử dụng trên hầu hết các hệ thống Unix hiện đại,<br>bao gồm GNU/Linux, Solaris, Irix, và cũng được sử dụng trên nhiều hệ thống nhúng. |
| **SOM/ESOM**  | SOM (System Object Module) và ESOM (Extended SOM) là định dạng tệp đối tượng và gỡ lỗi của HP<br>(không nên nhầm lẫn với SOM của IBM).                                                                                                                                                                              |

Nội dung của các object files thường được phân chia thành các khu vực được gọi là sections. Sections có thể chứa executable code, data, dynamic linking information (thông tin liên kết động), debugging data, symbol tables, relocation information (thông tin tái định vị), comments, string tables, và notes.

Một số sections được load trực tiếp vào process image để thực thi, một số khác chứa thông tin cần thiết trong quá trình xây dựng process image, và một số sections khác được sử dụng riêng cho quá trình linking các object files.

Việc phân chia sections là nguyên lý chung cho các định dạng của executable files. Lưu ý, tên gọi sections có thể khác nhau, vì nó còn tùy thuộc vào compiler/linker.

Bảng sau liệt kê một số section thường có trong executable file:

| **Section**            | **Mô tả**                                                                                                                                                                                           |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **.text**              | Chứa executable instruction codes và được chia sẻ giữa các process chạy cùng binary.<br>Thường chỉ có thể READ và EXECUTE, section này chịu ảnh hưởng nhiều nhất bởi tối ưu hóa.                    |
| **.bss**               | BSS (**B**lock **S**tarted by **S**ymbol).<br>Lưu trữ un-initialized variables (cả global và static).<br>Không chiếm không gian thực trong object file vì chỉ lưu kích thước cần thiết tại runtime. |
| **.data**              | Chứa initialized variables (cả global và static).<br>Thường là phần lớn nhất của executable, có quyền READ và WRITE.                                                                                |
| **.rdata**             | Còn gọi là .rodata (read-only data), chứa constants và string literals.                                                                                                                             |
| **.reloc**             | Lưu trữ thông tin cần để relocate image trong quá trình loading.                                                                                                                                    |
| **Symbol table**       | Symbol gồm name và address.<br>Symbol table lưu giữ thông tin cần thiết để locate và relocate các định nghĩa (definitions)<br>và tham chiếu (references) trong chương trình.                        |
| **Relocation records** | Lưu thông tin để kết nối symbolic references (tham chiếu ký hiệu)<br>với symbolic definitions (định nghĩa ký hiệu),<br>dùng bởi linker để điều chỉnh nội dung sections khi tạo program image.       |

Ví dụ sau đây minh họa việc hiển thị nội dung của object file bằng lệnh `readelf` (hoặc `objdump`). Lệnh `readelf` hoặc `objdump` đều dùng để phân tích các tệp ELF và có sẵn trong Linux, nhưng `readelf` tập trung vào cấu trúc tệp ELF hơn còn `objdump` tập trung vào mã của chương trình.

```c
/* testprog1.c */
#include <stdio.h>
static void display(int i, int *ptr);
int main(void)
{
    int x = 5;
    int *xptr = &x;

    printf("In main() program:\n");
    printf("x value is %d and is stored at address %p.\n", x, &x);
    printf("xptr pointer points to address %p which holds a value of %d.\n", xptr, *xptr);
    display(x, xptr);
    return 0;
}
void display(int y, int *yptr)
{
    char var[7] = "ABCDEF";
    printf("In display() function:\n");
    printf("y value is %d and is stored at address %p.\n", y, &y);
    printf("yptr pointer points to address %p which holds a value of %d.\n", yptr, *yptr);
}
```

Dùng GCC để biên dịch tệp chương trình `testprog1.c` trên thành object file:
```bash
$ gcc -c testprog1.c
# The gcc <-c> means compile and assemble, but do not link
```
Hiển thị nội dung của object file:
```bash
$ readelf -a testprog1.o
# The readelf <-a> means display all
# Or
$ objdump -s testprog1.o
# The objdump <-s> means display full contents of all sections requested
```

Nội dung của object file khi dùng lệnh `readelf`:
```bash
root@988ac2e024bd:/workspaces# readelf -a testprog1.o 
ELF Header:
  Magic:   7f 45 4c 46 02 01 01 00 00 00 00 00 00 00 00 00 
  Class:                             ELF64
  Data:                              2's complement, little endian
  Version:                           1 (current)
  OS/ABI:                            UNIX - System V
  ABI Version:                       0
  Type:                              REL (Relocatable file)
  Machine:                           Advanced Micro Devices X86-64
# ...still more...

Section Headers:
  [Nr] Name              Type             Address           Offset
       Size              EntSize          Flags  Link  Info  Align
  [ 0]                   NULL             0000000000000000  00000000
       0000000000000000  0000000000000000           0     0     0
  [ 1] .text             PROGBITS         0000000000000000  00000040
       000000000000013a  0000000000000000  AX       0     0     1
# ...still more...
```

Nội dung của object file khi dùng lệnh `objdump`:
```bash
root@988ac2e024bd:/workspaces# objdump -s testprog1.o 
testprog1.o:     file format elf64-x86-64
Contents of section .text:
 0000 f30f1efa 554889e5 4883ec20 64488b04  ....UH..H.. dH..
 0010 25280000 00488945 f831c0c7 45ec0500  %(...H.E.1..E...
 0020 0000488d 45ec4889 45f0488d 05000000  ..H.E.H.E.H.....
# ...still more...
Contents of section .rodata:
 0000 496e206d 61696e28 29207072 6f677261  In main() progra
 0010 6d3a0000 00000000 78207661 6c756520  m:......x value 
 0020 69732025 6420616e 64206973 2073746f  is %d and is sto
# ...still more...
Contents of section .comment:
 0000 00474343 3a202855 62756e74 75203131  .GCC: (Ubuntu 11
 0010 2e342e30 2d317562 756e7475 317e3232  .4.0-1ubuntu1~22
 0020 2e303429 2031312e 342e3000           .04) 11.4.0.    
# ...still more...
```

### 2.1. Relocation records

Mỗi object file chứa các tham chiếu đến mã hoặc dữ liệu bên trong chính nó và có thể tham chiếu đến các mã hoặc dữ liệu trong các object file khác (ví dụ: chương trình trong một tệp object file có thể gọi hàm hoặc tham chiếu đến các biến được định nghĩa ở một object file khác). Vì vậy, location (vị trí hoặc địa chỉ của các hàm và biến) cần được điều chỉnh thông qua quá trình relocation để kết hợp chính xác trong giai đoạn linking.

Tóm lại:
- Relocation là quá trình chỉnh sửa các địa chỉ tham chiếu (references) trong một object file để trỏ đến vị trí chính xác sau khi tất cả các object file được kết hợp lại.
- Linking là bước kết hợp nhiều object files để tạo thành một executable file. Trong quá trình này, linker sẽ thực hiện relocation để đảm bảo rằng các địa chỉ được trỏ đến chính xác.

Ví dụ: Object file có `main()` và nó gọi đến các hàm `funct()` và `printf()`, sau khi linking tất cả các object file với nhau, linker sẽ sử dụng relocation records để tìm tất cả các địa chỉ cần điền để tạo executable file.

![light mode only][img_2]{: width="457" height="441" .light }
![dark mode only][img_2d]{: width="457" height="441" .dark }

### 2.2. Symbol table

Symbol table (bảng ký hiệu) là gì và tại sao cần thiết?
- Khi assembly code được biên dịch thành machine code, các labels (nhãn) dùng để định danh các hàm, biến, hoặc địa chỉ trong mã nguồn sẽ bị loại bỏ. Tuy nhiên, để hỗ trợ các bước như linking object files hoặc debugging, những thông tin này vẫn cần được lưu giữ ở đâu đó. Đây chính là vai trò của symbol table:
  + Symbol table là một bảng chứa danh sách các tên (ví dụ: tên hàm, biến) và offset (vị trí) tương ứng của chúng trong các section như `.text` hoặc `.data`.
  + Ví dụ, nếu chương trình gọi một hàm `funct()`, symbol table sẽ chỉ ra địa chỉ của hàm đó nằm ở đâu trong `.text` section.
  + Disassembler (trình giải mã ngược) có thể sử dụng symbol table để chuyển đổi ngược từ một object file hoặc executable file thành mã nguồn gần giống ban đầu.
- Tóm lại: Symbol table giữ vai trò như một "bản đồ" cho các labels và tên trong code, giúp quá trình linking và phân tích ngược mã sau này dễ dàng hơn.

## 3. Linking

## 4. Tài liệu tham khảo

- [1] Article: *COMPILER, ASSEMBLER, LINKER AND LOADER: A BRIEF STORY* [Online]. Available: [link](https://www.tenouk.com/ModuleW.html).

[//]: # (----------SCOPE OF DECLARATION OF LIST OF IMAGES USED IN POST----------)
[img_1]: /assets/img/2024-12-C-CXX-building-process/01_compile_link_execute_stages_running_program.png "Các bước xây dựng chương trình"
[img_1d]: /assets/img/2024-12-C-CXX-building-process/01d_compile_link_execute_stages_running_program.png "Các bước xây dựng chương trình"
[img_2]: /assets/img/2024-12-C-CXX-building-process/02_relocation_record_and_linking.png "Quá trình linking và relocation record"
[img_2d]: /assets/img/2024-12-C-CXX-building-process/02d_relocation_record_and_linking.png "Quá trình linking và relocation record"
