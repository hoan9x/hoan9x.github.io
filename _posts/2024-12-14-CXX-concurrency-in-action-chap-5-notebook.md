---
title: "Chương 5: The C++ memory model and operations on atomic types"
description: Ghi chép trong quá trình đọc cuốn sách C++ Concurrency in Action của Anthony Williams
author: hoan9x
date: 2024-12-14 10:00:00 +0700
categories: [CXX, Multi-Threading]
mermaid: true
---

> Bài viết này vẫn chưa hoàn thiện.
{: .prompt-warning }

Chương này đề cập tới:
- Chi tiết về C++ memory model.
- Các kiểu dữ liệu atomic trong C++ Standard Library.
- Các operations có sẵn trên các kiểu dữ liệu này.
- Cách sử dụng các operations để synchronization giữa các threads.

Một tính năng quan trọng trong C++ Standard Library là memory model hỗ trợ multithreading, giúp các công cụ như mutexes, condition variables, futures, latches, và barriers hoạt động ổn định.

Lập trình viên thường không cần quan tâm chi tiết, trừ khi làm việc gần phần cứng. Với vai trò ngôn ngữ lập trình hệ thống, C++ cung cấp các atomic types và operations để đồng bộ hóa ở mức thấp, thường chỉ cần một vài lệnh CPU.

Chương này giới thiệu memory model, atomic types, và cách sử dụng chúng để đồng bộ hóa. Chủ đề này phức tạp, nhưng nó sẽ cần thiết nếu bạn dự định viết các cấu trúc dữ liệu không khóa (lock-free data structures) sẽ được đề cập ở chương 7.

## 1. Cơ bản về memory model

Memory model có hai khía cạnh:
- Khía cạnh structural: Liên quan đến cách bố trí dữ liệu trong bộ nhớ, đặc biệt quan trọng khi làm việc với các atomic operations cấp thấp.
- Khía cạnh concurrency: Xử lý song song giữa các threads.

### 1.1. Objects và memory locations

Trong C++, mọi dữ liệu, từ các biến cơ bản như `int`, `float` đến các instance của class, đều được coi là objects. Một object được định nghĩa là một region of storage (vùng lưu trữ) với các thuộc tính như type và lifetime.
> Khi nói **mọi dữ liệu đều là objects** chỉ đúng trong ngữ cảnh bộ nhớ của C++. Các kiểu như `int`, `float` trong C++ không hỗ trợ kế thừa hoặc có member functions, khác với cách sử dụng objects trong các ngôn ngữ như Smalltalk hay Ruby, nơi kiểu cơ bản cũng có thể được mở rộng hoặc xử lý như một object class.
{: .prompt-info }

Đặc điểm của Objects:
- Có thể là các kiểu cơ bản như `int` hoặc `float`.
- Có thể là các instance của class do người dùng định nghĩa.
- Một số objects (như array, instance của derived class, hoặc instance của class có non-static data members) sẽ chứa sub-objects, trong khi một số khác thì không.

Memory locations:
- Mỗi object được lưu trữ trong một hoặc nhiều memory locations.
- Một memory location có thể là:
    + Một object (hoặc sub-object) thuộc scalar type (kiểu dữ liệu cơ bản như `int` hay kiểu trỏ `my_class*`).
    + Một dãy bit fields liền kề (các bit fields liền kề là các objects riêng biệt nhưng lại chia sẻ cùng một memory location).

Hình minh họa sau mô tả cách một struct chia thành các objects và memory locations:
![light mode only][img_1]{: width="830" height="600" .light }
![dark mode only][img_1d]{: width="830" height="600" .dark }

Giải thích:
- Toàn bộ struct là một object chính, chia thành nhiều sub-objects, mỗi cái tương ứng với một data member.
- Các bit fields `bf1` và `bf2` chia sẻ một memory location.
- Bit field `bf3` có độ dài 0 không có memory location nhưng lại tách `bf4` thành một memory location riêng.
- `std::string s` sử dụng nhiều memory locations.

Những điểm quan trọng cần nhớ:
- Mọi variable là một object, kể cả khi chúng là thành viên của object khác.
- Mọi object chiếm ít nhất một memory location.
- Biến kiểu cơ bản như `int` hoặc `char` chiếm đúng một memory location, bất kể kích thước của chúng, dù chúng liền kề hoặc nằm trong array.
- Các bit fields liền kề nằm trong cùng một memory location.

Tiếp theo, chúng ta sẽ giải thích objects và memory locations thì liên quan gì đến concurrency.

### 1.2. Objects, memory locations và concurrency

Tránh race condition, nhằm bảo vệ dữ liệu khỏi sự thay đổi không mong muốn bởi các thread là yếu tố cốt lõi trong lập trình multithread. Hiểu sâu hơn, việc thay đổi dữ liệu chính là truy cập vào memory location.

- Nếu hai thread truy cập vào các memory location khác nhau, không có vấn đề gì; chương trình sẽ hoạt động bình thường.
- Nếu hai thread truy cập cùng một memory location, cần xem xét:
    + Cả hai chỉ đọc dữ liệu (read-only): Không cần đồng bộ hoặc bảo vệ vì không xảy ra xung đột.
    + Một hoặc cả hai thread ghi dữ liệu (write): Rất dễ xảy ra race condition rồi dẫn đến undefined behavior.

Phân biệt race condition và data race:
- Race condition: Đã được giải thích khá rõ ở chương 3, và race condition có thể dẫn đến lỗi logic hoặc undefined behavior, nhưng không phải lúc nào cũng gây undefined behavior.
- Data race: Là một trường hợp cụ thể của race condition, xảy ra khi hai thread cùng truy cập một memory location với ít nhất một thread ghi (write), và không có bất kỳ cơ chế đồng bộ hóa nào. Data race luôn dẫn đến undefined behavior, và vì thế nó nguy hiểm hơn so với race condition.

> Ghi chú thú vị: Tác giả Anthony Williams đã gặp trường hợp undefined behavior khiến màn hình của một lập trình viên bốc cháy! Có thể đây chỉ mang đính cảnh báo hài hước, nhưng nó làm nổi bật mức độ nguy hiểm của lỗi này.
{: .prompt-info }

Cách tránh data race, nguyên nhân trực tiếp dẫn tới undefined behavior:
- Mutex (đã giới thiệu ở chương 3): Đồng bộ hóa giữa các thread, giúp giải quyết race condition, bao gồm cả data race.
- Atomic operations (sẽ giới thiệu ở chương này): Đồng bộ hóa các thao tác đọc/ghi (sửa đổi) trên dữ liệu, giúp tránh undefined behavior, nhưng không ngăn được race condition, vì thứ tự thứ tự sửa đổi (modification orders) vẫn chưa được xác định.

### 1.3. Modification orders

## 2. Tài liệu tham khảo

- [1] Anthony Williams, "5. The C++ memory model and operations on atomic types" in *C++ Concurrency in Action*, 2nd Edition, 2019.

[//]: # (----------LIST OF IMAGES----------)
[img_1]: /assets/img/2024-12-CXX-concurrency-chap-5/01_division_of_struct_into_objects_and_memory_locations.png "Phân chia struct thành các objects và memory locations"
[img_1d]: /assets/img/2024-12-CXX-concurrency-chap-5/01d_division_of_struct_into_objects_and_memory_locations.png "Phân chia struct thành các objects và memory locations"
