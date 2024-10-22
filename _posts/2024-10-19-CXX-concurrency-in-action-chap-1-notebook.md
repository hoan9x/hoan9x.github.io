---
title: "Chương 1: Hello, world of concurrency in C++"
description: Ghi chép trong quá trình đọc cuốn sách C++ Concurrency in Action của Anthony Williams
author: hoan9x
date: 2024-10-19 11:00:00 +0700
categories: [CXX, Multi-Threading]
mermaid: true
---

Chương này đề cập tới:
- Ngữ nghĩa của concurrency và multithreading.
- Tại sao bạn sẽ muốn sử dụng concurrency và multithreading.
- Lịch sử của concurrency trong C++.
- Chương trình C++ đơn giản với multithreaded trông như thế nào.

## 1. Concurrency (đồng thời) là gì?

Concurrency được hiểu là những hoạt động riêng biệt diễn ra cùng lúc. Ví dụ: vừa đi bộ - vừa nói chuyện, vừa xem phim - vừa ăn uống, v.v...

### 1.1. Concurrency trong hệ thống máy tính

Thuật ngữ concurrency trong máy tính có nghĩa là máy tính có thể làm nhiều việc cùng một lúc, đây không phải là một điều gì mới mẻ.
- Trong quá khứ: Tại một thời điểm, máy tính chỉ làm được một task (tác vụ, công việc). Để tạo cảm giác concurrency, máy tính sẽ thực hiện chuyển qua chuyển lại thật nhanh chóng giữa các task để hoàn thành nó (gọi lại task switching).
- Hiện tại và tương lai: Với máy tính multi-processors (có nhiều bộ xử lý), hoặc máy tính multi-cores within a processor (có nhiều lõi trong một bộ xử lý), hoặc máy tính kết hợp cả hai, thì chúng đều có thể thật sự làm nhiều tasks cùng một lúc (gọi là hardware concurrency).

![light mode only][img_1]{: width="800" height="280" .light }
![dark mode only][img_1d]{: width="800" height="280" .dark }
_Hình 1.1. Hai cách để đạt được tính concurrency._

*Hình 1.1*. là một kịch bản mà máy tính có hai task cần thực hiện, mỗi task được chia thành 10 phần (cho thời gian thực hiện các phần lý tưởng là bằng nhau).
- Trên máy tính dual-core, mỗi task có thể thực hiện các phần trên lõi riêng của nó.
- Trên máy tính single-core, thực hiện task switching nên các phần khối từ mỗi task được xen kẽ.

Nhưng để thực hiện task switching, hệ điều hành cần tiến hành context switching (chuyển đổi ngữ cảnh), đây là quá trình tạm dừng một task đang chạy để chuyển sang task khác. Hệ điều hành sẽ lưu trạng thái CPU và con trỏ lệnh của task hiện tại, chọn task mới và khôi phục trạng thái CPU cho task đó. Việc này tốn thời gian, và thời gian chuyển đổi ngữ cảnh này được thể hiện bằng các khe chen giữa các khối phần task trong hệ thống single-core như *Hình 1.1*.

Mặc dù tính concurrency vượt trội hơn trong hệ thống multi-core processors, nhưng task switching vẫn là một kỹ thuật quan trọng. Ngay cả khi hệ thống có nhiều hardware threads[^fn-hw-threads], việc sử dụng task switching vẫn cần thiết để quản lý hiệu quả các tài nguyên hệ thống, đặc biệt khi số lượng task lớn.

![light mode only][img_2]{: width="770" height="190" .light }
![dark mode only][img_2d]{: width="770" height="190" .dark }
_Hình 1.2. Task switching của 4 tasks trên hệ thống dual-core._

*Hình 1.2* là ví dụ cho việc sử dụng task switching giữa 4 tasks trên hệ thống dual-core lý tưởng. Trong thực tế, nhiều vấn đề sẽ xảy ra khiến các phần chia task về mặt thời gian sẽ không đồng đều như vậy.

### 1.2. Các phương pháp tiếp cận concurrency

Hãy tưởng tượng có hai lập trình viên cùng làm việc trong một dự án, chúng ta có thể tổ chức hai cách làm việc như:
- Mỗi người làm việc độc lập tại văn phòng riêng, sử dụng tài liệu riêng và giao tiếp qua điện thoại hoặc email.
- Cả hai cùng làm việc trong một văn phòng chung, dùng chung tài liệu và trao đổi trực tiếp, nhưng có thể gây mất tập trung hoặc tranh chấp.

Hai cách tổ chức trên minh họa cho hai phương pháp tiếp cận concurrency:
- Multiple single-threaded processes (nhiều tiến trình đơn luồng): Dễ lập trình và nó an toàn, nhưng giao tiếp phức tạp và tốn tài nguyên.
- Multiple threads in a single process (nhiều luồng trong một tiến trình): Giao tiếp đơn giản, tiết kiệm tài nguyên, nhưng dễ gây ra sự tranh chấp.

Có thể kết hợp tùy ý hai cách tiếp cận concurrency, nhưng quy tắc là giống nhau.

- Đồng thời với nhiều tiến trình (CONCURRENCY WITH MULTIPLE PROCESSES):
  + Chia nhỏ ứng dụng thành nhiều process độc lập, giống như chạy nhiều ứng dụng cùng một lúc. Sử dụng kênh giao tiếp IPC[^fn-ipc] như signals, sockets, files, pipes, v.v.. (*Hình 1.3*).
  + Nhược điểm: Giao tiếp phức tạp, chậm và tốn tài nguyên khởi tạo và quản lý process.
  + Ưu điểm: Dễ lập trình an toàn, mã nguồn đáng tin cậy. Có thể cho chạy các process trên các hệ thống riêng biệt và cho chúng giao tiếp qua mạng, điều này có thể tăng chi phí, nhưng lợi dụng tốt có thể tăng tính mở rộng và cải thiện hiệu suất.

![light mode only][img_3]{: width="892" height="208" .light }
![dark mode only][img_3d]{: width="892" height="208" .dark }
_Hình 1.3. Giao tiếp giữa các process chạy đồng thời._

- Đồng thời với nhiều luồng (CONCURRENCY WITH MULTIPLE THREADS):
  + Chạy nhiều thread trong cùng một process, thread giống như là một process nhưng nhẹ hơn (lightweight process). Các thread có cùng không gian bộ nhớ nên dễ dàng truy cập dữ liệu chung.
  + Nhược điểm: Rủi ro khi truy cập dữ liệu không đồng bộ, cần cẩn thận khi lập trình.
  + Ưu điểm: Nhanh, ít tốn tài nguyên.

![light mode only][img_4]{: width="892" height="208" .light }
![dark mode only][img_4d]{: width="892" height="208" .dark }
_Hình 1.4. Giao tiếp giữa các thread chạy đồng thời._

So sánh ưu nhược điểm của hai cách tiếp cận, thì cách tiếp cận concurrency với nhiều thread được ưa chuộng hơn trong các ngôn ngữ lập trình, bao gồm cả C++. Ngoài ra, C++ không hỗ trợ giao tiếp giữa các process (IPC[^fn-ipc]), nên ứng dụng sử dụng cách tiếp cận concurrency với nhiều process phải lập trình dựa trên APIs riêng biệt của hệ điều hành.

### 1.3. Concurrency (đồng thời) so với parallelism (song song)

Thuật ngữ concurrency và parallelism có ý nghĩa tương đồng khi nói về multithreaded code (mã đa luồng), nhưng có khác biệt về trọng tâm và mục đích sử dụng:
- Concurrency tập trung vào việc quản lý các task hoặc cải thiện khả năng phản hồi.
- Parallelism chú trọng vào hiệu suất, tối ưu hóa phần cứng để xử lý dữ liệu.

Dù sự khác biệt không hoàn toàn rõ ràng, nhưng việc phân biệt này giúp các cuộc thảo luận dễ dàng hơn.

## 2. Tại sao nên sử dụng đồng thời (concurrency)?

Có hai lý do chính:
- Tách biệt mối quan tâm (separation of concerns): Để tổ chức mã nguồn tách biệt, dễ quản lý.
- Tăng hiệu suất: Tận dụng phần cứng để tăng tốc độ xử lý.

Ví dụ về sử dụng concurrency với ứng dụng trình phát DVD:
- Tách biệt mối quan tâm: Cho một thread xử lý giao diện với người dùng, một thread xử lý việc phát lại DVD.
- Tăng hiệu suất: Sử dụng nhiều lõi CPU để tăng tốc giải mã video và âm thanh.

Khi nào không nên sử dụng concurrency?
- Chi phí vượt quá lợi ích: Việc viết và bảo trì mã dùng concurrency có thể phức tạp và tốn kém.
- Hiệu suất kém: Tạo thread mất thời gian, đôi khi còn làm ứng dụng chậm hơn.
- Tài nguyên hạn chế: Quá nhiều thread trên phần cứng yếu có thể gây chậm và thiếu bộ nhớ.
- Context switching: Nhiều thread làm tăng thời gian chuyển đổi ngữ cảnh, giảm hiệu suất.

## 3. Concurrency và multithreading trong C++

Việc hỗ trợ concurrency thông qua multithreading chỉ được đưa vào tiêu chuẩn C++ từ phiên bản C++11 trở đi. Trước đó, để thực hiện lập trình multithreading, lập trình viên buộc phải sử dụng các phần mở rộng tùy thuộc vào từng nền tảng.

### 3.1. Lịch sử của multithreading trong C++

Trước C++11, lập trình multithreading gặp nhiều hạn chế:
- Tiêu chuẩn C++ 1998 chưa hỗ trợ multithreading: Mô hình bộ nhớ không rõ ràng, lập trình viên phải dựa vào các phần mở rộng của trình biên dịch.
- Phụ thuộc vào nền tảng: Sử dụng APIs multithreading phụ thuộc hệ điều hành (POSIX, Windows), làm mã kém tính tương thích.
- Thiếu tiêu chuẩn thống nhất: Các thư viện multithreading còn sơ khai và không đồng nhất.

C++11 đã khắc phục:
- Hỗ trợ chuẩn cho multithreading: Thêm thư viện và công cụ hỗ trợ (C++ Thread Library).
- Xác định rõ mô hình bộ nhớ: Giúp hiểu rõ cách các thread tương tác.
- Tăng tính tương thích: Mã nguồn sử dụng C++ Thread Library có thể chạy được trên nhiều nền tảng.

### 3.2. Hiệu suất của C++ Thread Library

- Mối quan tâm về hiệu suất: Lập trình viên thường lo lắng về hiệu suất khi sử dụng các thư viện C++ cấp cao, bao gồm C++ Thread Library.
- Abstraction penalty[^fn-abstraction-penalty] (chi phí/hình phạt trừu tượng hóa): Sử dụng các APIs cấp cao có thể làm giảm hiệu suất so với sử dụng trực tiếp các APIs cấp thấp.
- Mục tiêu thiết kế của C++ Thread Library: Giảm thiểu abstraction penalty và đảm bảo hiệu suất tương đương với sử dụng APIs cấp thấp. Cung cấp thư viện, hạ tầng cấp thấp là atomic (nguyên tử) để kiểm soát trực tiếp từng bit, byte và đồng bộ hóa giữa các thread.

Nói chung: C++ Thread Library giúp lập trình dễ dàng, nhưng vẫn có thể ảnh hưởng đến hiệu suất. Khi muốn tối ưu hóa hiệu suất, hãy sử dụng các APIs cấp thấp mà platform-specific (là APIs dành riêng trên mỗi hệ điều hành).

## 4. Hello, Concurrent World

Đây là một chương trình "Hello World" single-thread (đơn luồng):
```cpp
#include <iostream>
int main()
{
    std::cout << "Hello World\n";
}
```

Đây là một chương trình "Hello Concurrent World" multi-thread (đa luồng):
```cpp
#include <iostream>
#include <thread>
void hello()
{
    std::cout << "Hello Concurrent World\n";
}
int main()
{
    std::thread t(hello);
    t.join();
}
```

Ví dụ đơn giản về "Hello World" và "Hello Concurrent World" minh họa cách dùng multithreading. Chương trình "Hello Concurrent World" dùng C++ Thread Library `<thread>`, nó tách phần in lời chào thành một hàm riêng `hello()` và khởi tạo một thread mới `std::thread t(hello);`. Lệnh `t.join()` đảm bảo `main()` thread chờ `hello()` thread hoàn thành trước khi kết thúc chương trình. Vì đây chỉ là ứng dụng đơn giản nên sử dụng multithreading không mang lại lợi ích gì đáng kể.

## 5. Tài liệu tham khảo

- [1] Anthony Williams, "1. Hello, world of concurrency in C++!" in *C++ Concurrency in Action*, 2nd Edition, 2019.

## 6. Chú thích

[^fn-hw-threads]: Hardware threads là thước đo số lượng task độc lập mà phần cứng có thể thực sự chạy đồng thời. Mỗi core trong bộ xử lý có thể hỗ trợ nhiều hardware threads thông qua công nghệ như [Hyper-Threading](https://www.intel.com/content/www/us/en/gaming/resources/hyper-threading.html) của CPU Intel, cho phép một core xử lý nhiều hơn một task cùng lúc.

[^fn-abstraction-penalty]: Abstraction penalty là một khái niệm trong lập trình, đặc biệt trong các hệ thống nhúng hoặc các hệ thống đòi hỏi hiệu suất cao. Nó đề cập đến sự giảm sút hiệu năng khi chúng ta sử dụng các lớp trừu tượng, các thư viện hoặc các framework cấp cao so với việc viết trực tiếp mã ở cấp độ thấp hơn.

[^fn-ipc]: IPC - Inter Process Communication.

[//]: # (----------LIST OF IMAGES----------)
[img_1]: /assets/img/2024-10-CXX-concurrency-chap-1/01_two_concurrency_approaches.png "Two Concurrency Approaches"
[img_1d]: /assets/img/2024-10-CXX-concurrency-chap-1/01d_two_concurrency_approaches.png "Two Concurrency Approaches"
[img_2]: /assets/img/2024-10-CXX-concurrency-chap-1/02_task_switching_multi_core.png "Task switching of four tasks on two cores"
[img_2d]: /assets/img/2024-10-CXX-concurrency-chap-1/02d_task_switching_multi_core.png "Task switching of four tasks on two cores"
[img_3]: /assets/img/2024-10-CXX-concurrency-chap-1/03_ipc_in_concurrency.png "IPC of concurrently running processes"
[img_3d]: /assets/img/2024-10-CXX-concurrency-chap-1/03d_ipc_in_concurrency.png "IPC of concurrently running processes"
[img_4]: /assets/img/2024-10-CXX-concurrency-chap-1/04_comm_between_threads_concurrently.png "Communication between threads running concurrently"
[img_4d]: /assets/img/2024-10-CXX-concurrency-chap-1/04d_comm_between_threads_concurrently.png "Communication between threads running concurrently"
