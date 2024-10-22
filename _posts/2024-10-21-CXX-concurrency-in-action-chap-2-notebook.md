---
title: "Chương 2: Managing threads"
description: Ghi chép trong quá trình đọc cuốn sách C++ Concurrency in Action của Anthony Williams
author: hoan9x
date: 2024-10-21 10:00:00 +0700
categories: [CXX, Multi-Threading]
mermaid: true
---

> Bài viết này vẫn chưa hoàn thiện.
{: .prompt-warning }

Chương này đề cập tới:
- Khởi tạo thread, và các cách khác nhau để chỉ định mã nguồn chạy trên thread mới.
- Chờ thread kết thúc hay cứ để nó chạy tiếp tự do?
- Nhận dạng duy nhất của thread.

## 1. Bắt đầu với quản lý thread

### 1.1. Khởi tạo một thread

Trong C++ Thread Library, thread được khởi tạo bằng cách tạo đối tượng `std::thread`, và chỉ định task chạy trên thread đó:

```cpp
void do_some_work();
std::thread my_thread(do_some_work);
```

Hàm `do_some_work` là một task sẽ được khởi chạy trên thread riêng. Thật ra `std::thread` có thể được khởi tạo với bất kỳ kiểu dữ liệu nào có thể được coi như là một hàm (callable type) bao gồm:
- Hàm ví dụ như `do_some_work` bên trên.
- Đối tượng có toán tử hàm gọi `operator()`.
- Biểu thức lambda.

Khởi tạo bằng đối tượng class có `operator()`:
```cpp
class background_task
{
public:
    void operator()() const
    {
        do_something();
        do_something_else();
    }
};
background_task f;
std::thread my_thread(f);
```

Khởi tạo bằng biểu thức lambda:
```cpp
std::thread my_thread([]{
    do_something();
    do_something_else();
});
```

## 2. Tài liệu tham khảo

- [1] Anthony Williams, "2. Managing threads" in *C++ Concurrency in Action*, 2nd Edition, 2019.
