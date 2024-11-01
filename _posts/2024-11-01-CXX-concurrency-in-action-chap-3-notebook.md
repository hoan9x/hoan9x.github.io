---
title: "Chương 3: Sharing data between threads"
description: Ghi chép trong quá trình đọc cuốn sách C++ Concurrency in Action của Anthony Williams
author: hoan9x
date: 2024-11-01 10:00:00 +0700
categories: [CXX, Multi-Threading]
mermaid: true
---

> Bài viết này vẫn chưa hoàn thiện.
{: .prompt-warning }

Chương này đề cập tới:
- Vấn đề khi chia sẻ dữ liệu giữa các threads.
- Bảo vệ dữ liệu được chia sẻ với mutex.
- Giải pháp thay thế để bảo vệ dữ liệu được chia sẻ.

Một trong những lợi ích chính của việc sử dụng nhiều threads để xử lý đồng thời là khả năng dễ dàng chia sẻ dữ liệu giữa chúng. Tuy nhiên, việc chia sẻ dữ liệu cũng đi kèm với nhiều vấn đề. Ví dụ, khi bạn sống chung phòng trọ với người khác, bạn không thể sử dụng bếp hay nhà tắm cùng một lúc mà không có quy tắc rõ ràng. Tương tự, trong lập trình, khi các threads chia sẻ dữ liệu, cần có quy định về quyền truy cập và cập nhật dữ liệu giữa các threads. Mặc dù việc chia sẻ dữ liệu giữa nhiều threads có thể hữu ích, nhưng sử dụng sai cách có thể dẫn đến nhiều lỗi nghiêm trọng. Chương này sẽ tập trung vào việc chia sẻ dữ liệu một cách an toàn giữa các threads trong C++, tránh những vấn đề tiềm ẩn và tối đa hóa lợi ích khi chia sẻ dữ liệu.

## 1. Vấn đề khi chia sẻ dữ liệu giữa các threads

Vấn đề khi chia sẻ dữ liệu giữa các threads chủ yếu xuất phát từ việc sửa đổi dữ liệu. *Nếu dữ liệu được chia sẻ mà chỉ có thể đọc (read-only) thì sẽ không có vấn đề gì*. Còn khi dữ liệu được sửa đổi, nó sẽ có rủi ro.

Một khái niệm được sử dụng rộng rãi để giúp các lập trình viên lý luận về mã của họ là invariants (sự bất biến). Những invariants này thường bị hỏng trong quá trình cập nhật dữ liệu.

Ví dụ các bước để xóa một node khỏi doubly linked list (danh sách liên kết đôi):

a. Xác định một node để xóa, ví dụ node N.

![light mode only][img_1]{: width="800" height="280" .light }
![dark mode only][img_1d]{: width="800" height="280" .dark }

b. Cập nhật liên kết từ node N-1 để trỏ đến node N+1.

![light mode only][img_2]{: width="800" height="280" .light }
![dark mode only][img_2d]{: width="800" height="280" .dark }

c. Cập nhật liên kết từ node N+1 để trỏ đến node N-1.

![light mode only][img_3]{: width="800" height="280" .light }
![dark mode only][img_3d]{: width="800" height="280" .dark }

d. Xóa node N.

![light mode only][img_4]{: width="800" height="280" .light }
![dark mode only][img_4d]{: width="800" height="280" .dark }

Xem xét trường hợp: Nếu một thread đang duyệt qua linked list để đọc dữ liệu trong khi một thread khác đồng thời xóa một node, thread đọc có thể thấy list với các node chỉ bị xóa một phần. Điều này vi phạm tính invariant, dẫn đến lỗi khi thread đọc vẫn truy cập dữ liệu của node đã bị xóa. Đây là một ví dụ điển hình về *race condition* — một trong những nguyên nhân phổ biến gây lỗi trong lập trình đồng thời khi các thread truy cập tài nguyên chung mà không được đồng bộ hóa đúng cách.

### 1.1. Race conditions

Giả sử bạn đang mua vé xem phim tại rạp và nhiều người cũng đang đặt vé cùng lúc, chỗ ngồi còn trống sẽ tùy thuộc vào việc ai đặt trước. Khi chỉ còn vài chỗ, đó có thể là cuộc đua để xem ai mua được. Đây là ví dụ về *race condition*, nơi kết quả phụ thuộc vào thứ tự thực hiện thao tác từ người đặt vé.

Trong lập trình đồng thời, race condition xảy ra khi kết quả phụ thuộc vào thứ tự thực thi của các thread. Chuẩn C++ định nghĩa *data race* là một loại race condition cụ thể, xảy ra khi nhiều thread cùng sửa đổi một đối tượng (sẽ được trình bày trong chương 5).

Tóm lại, race condition thường xuất hiện khi việc hoàn thành một thao tác yêu cầu sửa đổi nhiều phần dữ liệu khác nhau. Điều này có thể gây khó khăn trong việc phát hiện và tái hiện vấn đề, vì thời gian xảy ra sự cố thường rất ngắn, nên các vấn đề về race condition có thể biến mất khi chạy gỡ lỗi. Việc viết chương trình multi-threads thường gặp khó khăn do phải tránh các vấn đề race condition.

### 1.2. Ngăn chặn race conditions

Có nhiều cách để xử lý các vấn đề race conditions. Cách đơn giản nhất là bọc cấu trúc dữ liệu của bạn bằng một cơ chế bảo vệ, đảm bảo rằng chỉ thread đang thực hiện sửa đổi dữ liệu mới có thể truy cập vào được dữ liệu. Thư viện chuẩn C++ cung cấp cơ chế bảo vệ là *mutex*, và nó sẽ được đề cập trong chương này.

Một cách khác là thiết kế lại cấu trúc dữ liệu để các sửa đổi trên nó được thực hiện dưới dạng một loạt các thay đổi không thể chia nhỏ. Đây được gọi là lock-free programming (lập trình không khóa), nhưng nó rất khó để thực hiện (chi tiết hơn ở chương 7).

Còn một cách nữa để xử lý race condition là coi việc cập nhật dữ liệu như một transaction (giao dịch), tương tự như cập nhật cơ sở dữ liệu. Các sửa đổi và đọc dữ liệu được lưu trong một transaction log (nhật ký giao dịch) rồi được xác nhận trong một bước duy nhất. Nếu việc xác nhận không thể hoàn thành, thì cấu trúc dữ liệu đã bị sửa đổi bởi thread khác, transaction sẽ được khởi động lại. Cách này được gọi là software transactional memory (STM), và nó sẽ không được đề cập tới trong cuốn sách này.

## 2. Bảo vệ dữ liệu được chia sẻ với mutex

Để bảo vệ dữ liệu được chia sẻ khỏi race condition, bạn có thể sử dụng *mutex* (**mut**ual **ex**clusion: loại trừ lẫn nhau). Bằng cách khóa mutex trước khi truy cập dữ liệu và mở khóa sau khi hoàn tất, nó đảm bảo rằng chỉ một thread có thể truy cập vào dữ liệu tại một thời điểm. Tuy nhiên, mutex không phải là giải pháp hoàn hảo, bạn cần chú ý đến việc bảo vệ đúng dữ liệu cũng như các vấn đề như *deadlock*.

### 2.1. Sử dụng mutex trong C++

Trong C++, mutex được tạo bằng cách khai báo instance của `std::mutex`, sử dụng hàm thành viên là `lock()` và `unlock()` để khóa và mở khóa mutex.
```cpp
#include <iostream>
#include <string>
#include <thread>
#include <mutex>
int main()
{
    int count = 0;
    const int ITERATIONS = 1E6;
    std::mutex mtx;
    auto func = [&]()
    {
        for (int i = 0; i < ITERATIONS; i++)
        {
            mtx.lock();
            ++count;
            mtx.unlock();
        }
    };
    std::thread t1(func);
    std::thread t2(func);
    t1.join();
    t2.join();
    std::cout << std::to_string(count) << std::endl;
    return 0;
}
```

Không nên sử dụng `lock()` và `unlock()` một cách trực tiếp, nên sử dụng các class template như `std::lock_guard`.
```cpp
#include <list>
#include <mutex>
#include <algorithm>
std::list<int> some_list;
std::mutex some_mutex;
void add_to_list(int new_value)
{
    std::lock_guard<std::mutex> guard(some_mutex);
    some_list.push_back(new_value);
}
bool list_contains(int value_to_find)
{
    std::lock_guard<std::mutex> guard(some_mutex);
    return std::find(some_list.begin(), some_list.end(), value_to_find) != some_list.end();
}
```

## 3. Giải pháp thay thế để bảo vệ dữ liệu được chia sẻ

## 4. Tài liệu tham khảo

- [1] Anthony Williams, "3. Sharing data between threads" in *C++ Concurrency in Action*, 2nd Edition, 2019.

[//]: # (----------LIST OF IMAGES----------)
[img_1]: /assets/img/2024-11-CXX-concurrency-chap-3/01_a_deleting_node.png
[img_1d]: /assets/img/2024-11-CXX-concurrency-chap-3/01d_a_deleting_node.png
[img_2]: /assets/img/2024-11-CXX-concurrency-chap-3/02_b_deleting_node.png
[img_2d]: /assets/img/2024-11-CXX-concurrency-chap-3/02d_b_deleting_node.png
[img_3]: /assets/img/2024-11-CXX-concurrency-chap-3/03_c_deleting_node.png
[img_3d]: /assets/img/2024-11-CXX-concurrency-chap-3/03d_c_deleting_node.png
[img_4]: /assets/img/2024-11-CXX-concurrency-chap-3/04_d_deleting_node.png
[img_4d]: /assets/img/2024-11-CXX-concurrency-chap-3/04d_d_deleting_node.png
