---
title: "Chương 2: Managing threads"
description: Ghi chép trong quá trình đọc cuốn sách C++ Concurrency in Action của Anthony Williams
author: hoan9x
date: 2024-10-21 10:00:00 +0700
categories: [CXX, Multi-Threading]
mermaid: true
---

Chương này đề cập tới:
- Khởi tạo thread, và các cách khác nhau để chỉ định mã nguồn chạy trên thread mới.
- Chờ thread kết thúc hay cứ để nó chạy tiếp tự do?
- Nhận dạng duy nhất của thread.

## 1. Bắt đầu với quản lý thread

### 1.1. Khởi tạo một thread và đợi thread hoàn tất

Trong C++ Thread Library, thread được khởi tạo bằng cách tạo đối tượng `std::thread`, và chỉ định task chạy trên thread đó:
```cpp
void do_some_work();
std::thread my_thread(do_some_work);
```

Hàm `do_some_work` là một task sẽ được khởi chạy trên thread riêng. Thật ra `std::thread` có thể được khởi tạo với bất kỳ task là kiểu dữ liệu có thể được coi như là một hàm (callable type) bao gồm:
- Hàm, ví dụ như `do_some_work` bên trên.
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

Sau khi khởi chạy thread, tiếp theo bạn cần quyết định xem có nên đợi task trên thread chạy hoàn tất bằng `join()` hay để nó chạy tự do bằng `detach()`. Nếu bạn không quyết định `join()` hoặc `detach()` trước khi đối tượng `std::thread` bị hủy, thì chương trình của bạn sẽ bị chấm dứt.
```cpp
#include <iostream>
#include <thread>
void hello()
{
    std::cout << "Hello Concurrent World\n";
}
int main()
{
    {
        std::thread t(hello);
        /**------------------------------------------------------------------------
        * If you don’t decide join() or detach() before the std::thread object is destroyed,
        * then your program is terminated.
        *------------------------------------------------------------------------**/
    }
    /* This line has gone out of scope, so the std::thread object will be destroyed. */
    std::cout << "Main thread running\n";
}
```
{: #refer-code-0 }

Hành động `join()` sẽ dọn sạch bộ nhớ được liên kết với thread, do đó đối tượng std::thread sẽ không còn được liên kết với thread hiện đã hoàn tất task nữa (không liên kết với bất kỳ thread nào). Điều này có nghĩa là bạn chỉ có thể gọi `join()` một lần cho một thread nhất định, sau khi đã gọi `join()`, đối tượng std::thread không còn có thể `join()` được nữa và joinable() sẽ trả về false.
```cpp
std::thread t(hello);
if (t.joinable())
{
    std::cout << "joinable() before: " << (t.joinable()?"true":"false") << std::endl;
    t.join(); // or detach()
    std::cout << "joinable() after: " << (t.joinable()?"true":"false") << std::endl;
}
```

Khi dùng `detach()`, cần đảm bảo rằng dữ liệu mà thread đang truy cập là hợp lệ cho đến khi thread hoàn tất xử lý với dữ liệu đó, nếu không undefined behavior (hành vi không xác định) sẽ xảy ra.
```cpp
struct func
{
    int &i;
    func(int &i_) : i(i_) {}
    void operator()()
    {
        for (unsigned j = 0; j < 1000000; ++j)
        {
            do_something(i);
        }
    }
};
void oops()
{
    int some_local_state = 0;
    func my_func(some_local_state);
    std::thread my_thread(my_func);
    my_thread.detach();
}
```
{: #refer-code-1 }

Ví dụ với code trên, `my_thread` vẫn chạy vì `detach()` mặc dù hàm `oops()` đã thoát. Biến `i` trong struct đang được reference (tham chiếu) tới biến local (cục bộ) `some_local_state`, nên khi hàm `oops()` thoát, biến local sẽ được giải phóng. Nếu `my_thread` vẫn chạy và xử lý `do_something(i)`, undefined behavior sẽ xảy ra.

### 1.2. Đợi thread hoàn tất với chương trình có exception (ngoại lệ)

Như đã đề cập trước đó, `join()` hoặc `detach()` phải được gọi trước khi đối tượng std::thread bị hủy. `detach()` thường được gọi ngay sau khi thread khởi chạy nên thường không có vấn đề gì. Nhưng bạn cần phải cẩn thận chọn vị trí thích hợp trong mã để gọi `join()`, vì chương trình có exception có thể khiến `join()` bị bỏ qua. Nói chung, chú ý gọi `join()` khi có exception.
```cpp
struct func;
void f()
{
    int some_local_state = 0;
    func my_func(some_local_state);
    std::thread t(my_func);
    try
    {
        do_something_in_current_thread();
    }
    catch (...)
    {
        /* Be sure to call join() when an exception occurs */
        t.join();
        throw;
    }
    t.join();
}
```

Một cách lập trình khác để chắc chắn `join()` được gọi là sử dụng RAII[^fn-RAII], cách này tạo một class để thực hiện `join()` trong destructor (hàm hủy). 
```cpp
class thread_guard
{
    std::thread &t;
public:
    explicit thread_guard(std::thread &t_) : t(t_) {}
    ~thread_guard()
    {
        if (t.joinable())
        {
            t.join();
        }
    }
    thread_guard(thread_guard const &) = delete;
    thread_guard &operator=(thread_guard const &) = delete;
};
struct func;
void f()
{
    int some_local_state = 0;
    func my_func(some_local_state);
    std::thread t(my_func);
    thread_guard g(t);
    do_something_in_current_thread();
}
```
{: #refer-thread_guard }

### 1.3. Chạy thread ở chế độ nền (background)

Việc gọi `detach()` được hiểu là chạy thread ở background, thread được tách rời (detached) còn được gọi là daemon thread. Theo UNIX concept, một tiến trình daemon là tác vụ chạy ở background mà không có bất kỳ giao diện người dùng rõ ràng nào. Tóm lại, tách rời thread với các task muốn chạy nền như giám sát hệ thống hoặc cho các task kiểu fire-and-forget[^fn-fire-and-forget].

## 2. Passing arguments (truyền các đối số) cho task trong thread

Để passing argument[^fn-Parameter-vs-Argument] cho task là đối tượng có `operator()` thì bạn có thể truyền qua constructor (hàm tạo) của đối tượng, đã có ví dụ [ở trên](#refer-code-1). Còn task là một hàm, thì chỉ cần passing argument vào constructor (hàm tạo) của `std::thread` như sau:
```cpp
void f(int i, const std::string &s);
std::thread t(f, 3, "hello");
```

Nhưng điều quan trọng cần lưu ý là các parameters[^fn-Parameter-vs-Argument] (tham số) sẽ được sao chép vào bộ nhớ trong của thread mới tạo, rồi sau đó mới được truyền cho task dưới dạng rvalue như thể chúng là các giá trị tạm thời. Như ví dụ trên, mặc dù `f` có parameter thứ hai là `std::string`, nhưng passing argument lại là một chuỗi ký tự dạng `const char *`, và argument này sẽ chỉ được chuyển đổi thành `std::string` trong ngữ cảnh của thread mới. Điều này đặc biệt quan trọng khi passing argument là một con trỏ đến một biến tự động:
```cpp
void f(int i, const std::string &s);
void oops(int some_param)
{
    char buffer[1024];
    sprintf(buffer, "%i", some_param);
    std::thread t(f, 3, buffer);
    t.detach();
}
```

Ví dụ trong trường hợp trên, con trỏ `buffer` được truyền qua thread mới, và có khả năng là hàm `oops()` sẽ thoát trước khi `buffer` được chuyển đổi thành `std::string` trên thread mới, điều này dẫn đến undefined behavior. Giải pháp là ép kiểu thành `std::string` trước khi passing argument:
```cpp
void f(int i, const std::string &s);
void not_oops(int some_param)
{
    char buffer[1024];
    sprintf(buffer, "%i", some_param);
    std::thread t(f, 3, std::string(buffer));
    t.detach();
}
```

Trường hợp bạn muốn passing argument để thread cập nhật dữ liệu kiểu tham chiếu (pass by reference), ví dụ:
```cpp
void f(std::string &s)
{
    std::cout << "f() running\n";
    s = "update data";
}
void oops_again()
{
    std::string data{"data"};
    std::cout << "Before change:" << data << std::endl;
    std::thread t(f, data);
    t.join();
    std::cout << "After change:" << data << std::endl;
}
```

Ví dụ trên sẽ không thể biên dịch được, vì `f(std::string &s)` mong muốn pass by reference, nhưng constructor của `std::thread` không biết điều đó, nó không biết kiểu dữ liệu mà task đang mong đợi mà chỉ sao chép một cách mù quáng các giá trị argument được cung cấp (argument được sao chép dưới dạng rvalue). Do đó, `f(std::string &s)` sẽ được gọi bằng rvalue nên biên dịch lỗi. Giải pháp là bọc argument cần pass by reference trong `std::ref`:
```cpp
std::thread t(f, std::ref(data));
```

Nếu bạn quen thuộc với ngữ nghĩa truyền tham số của `std::bind`, thì constructor của `std::thread` hoạt động tương tự:
```cpp
class X
{
public:
    void do_lengthy_work(int i);
};
X my_x;
std::thread t(&X::do_lengthy_work, &my_x, 10);
```

Trường hợp passing argument với argument không thể sao chép mà chỉ có thể di chuyển (ví dụ `std::unique_ptr`), ta sẽ dùng `std::move`:
```cpp
void process_big_object(std::unique_ptr<big_object>);
std::unique_ptr<big_object> p(new big_object);
p->prepare_data(42);
std::thread t(process_big_object,std::move(p));
```

Dùng `std::move(p)` trong constructor `std::thread` thì quyền sở hữu của `big_object` trước tiên sẽ được chuyển vào bộ nhớ trong của thread mới, sau đó sẽ vào hàm `process_big_object()`.

## 3. Chuyển quyền sở hữu của thread

Kiểu sở hữu tài nguyên của `std::thread` tương tự như `std::unique_ptr`, nghĩa là quyền sở hữu thực thi của một thread chỉ có thể được `std::move` giữa các thread instances[^fn-instance], ví dụ:
```cpp
void some_function();
void some_other_function();
std::thread t1(some_function);
std::thread t2 = std::move(t1);
t1 = std::thread(some_other_function);
std::thread t3;
t3 = std::move(t2);
t1 = std::move(t3);
```
{: #refer-code-2 }

Phân tích ví dụ [trên](#refer-code-2):
- Dòng 3: Một thread `some_function` được khởi tạo và liên kết với instance `t1`.
- Dòng 4: Quyền sở hữu thread `some_function` của instance `t1` được chuyển qua instance `t2`, như vậy instance `t1` không còn liên kết với thread nào.
- Dòng 5: Một thread `some_other_function` được khởi tạo và liên kết với object `std::thread` tạm thời, sau đó quyền sở hữu của thread `some_other_function` của object `std::thread` được chuyển qua instance `t1`. Ở đây, không cần dùng `std::move()` để di chuyển vì việc di chuyển từ object tạm thời là tự động và ngầm định.
- Dòng 6: Instance `t3` được tạo mà không liên kết với thread task nào.
- Dòng 7: Quyền sở hữu của thread task được liên kết với `t2` được chuyển sang `t3`. Sau tất cả các lần di chuyển này, `t1` được liên kết với thread `some_other_function`, `t2` không có thread task nào và `t3` được liên kết với thread `some_function`.
- Dòng 8: Instance `t1` đang liên kết với thread `some_other_function`, nhưng `t1` lại được chuyển quyền sở hữu thread `some_function` từ `t3`. Như vậy, thread `some_other_function` sẽ bị hủy do không còn được liên kết với instance nào. Và như đã đề cập [ở đây](#refer-code-0), chương trình này sẽ bị chấm dứt do thread bị hủy trước khi gọi `join()`, `detach()`.

Cải thiện [`thread_guard`](#refer-thread_guard) đã trình bày ở trên, sử dụng `std::move` để chuyển quyền sở hữu thread:
```cpp
class scoped_thread
{
    std::thread t;
public:
    explicit scoped_thread(std::thread t_) : t(std::move(t_))
    {
        if(!t.joinable())
            throw std::logic_error("No thread");
    }
    ~scoped_thread()
    {
        t.join();
    }
    scoped_thread(scoped_thread const &) = delete;
    scoped_thread &operator=(scoped_thread const &) = delete;
};
struct func;
void f()
{
    int some_local_state;
    scoped_thread t{std::thread(func(some_local_state))};
    do_something_in_current_thread();
}
```
{: #refer-scoped_thread }

Class [`scoped_thread`](#refer-scoped_thread) là phiên bản mới của [`thread_guard`](#refer-thread_guard), nó tránh việc một ai đó có thể `join()` hoặc `detach()` thread bên ngoài `scoped_thread` vì quyền sở hữu thread đã thuộc về `scoped_thread`.

Đã có một đề xuất về việc thêm class `joining_thread` (ý tưởng tương tự như `scoped_thread`) vào tiêu chuẩn C++17, nhưng nó không được chấp thuận. Cho đến tiêu chuẩn C++20 thì nó mới được thêm vào thành class [`std::jthread`](https://en.cppreference.com/w/cpp/thread/jthread). Đây là triển khai của `joining_thread`:
```cpp
class joining_thread
{
    std::thread t;
public:
    joining_thread() noexcept = default;
    template <typename Callable, typename... Args>
    explicit joining_thread(Callable &&func, Args &&...args) : t(std::forward<Callable>(func), std::forward<Args>(args)...) {}
    explicit joining_thread(std::thread t_) noexcept : t(std::move(t_)) {}
    joining_thread(joining_thread &&other) noexcept : t(std::move(other.t)) {}
    joining_thread &operator=(joining_thread &&other) noexcept
    {
        if (joinable())
            join();
        t = std::move(other.t);
        return *this;
    }
    joining_thread &operator=(std::thread other) noexcept
    {
        if (joinable())
            join();
        t = std::move(other);
        return *this;
    }
    ~joining_thread() noexcept
    {
        if (joinable())
            join();
    }
    void swap(joining_thread &other) noexcept
    {
        t.swap(other.t);
    }
    std::thread::id get_id() const noexcept
    {
        return t.get_id();
    }
    bool joinable() const noexcept
    {
        return t.joinable();
    }
    void join()
    {
        t.join();
    }
    void detach()
    {
        t.detach();
    }
    std::thread &as_thread() noexcept
    {
        return t;
    }
    const std::thread &as_thread() const noexcept
    {
        return t;
    }
};
```

Việc `std::thread` hỗ trợ việc di chuyển quyền sở hữu, thì object `std::thread` cũng có thể được chứa trong các loại containers có hỗ trợ di chuyển như [`std::vector<T>::emplace_back`](https://en.cppreference.com/w/cpp/container/vector/emplace_back):
```cpp
void do_work(unsigned id);
void f()
{
    std::vector<std::thread> threads;
    for (unsigned i = 0; i < 20; ++i)
        threads.emplace_back(do_work, i);
    for (auto &entry : threads)
        entry.join();
}
```

## 4. Chọn số lượng thread tại thời điểm runtime

Một tính năng hữu ích trong C++ Thread Library là `std::thread::hardware_concurrency()`, nó cho biết số thread có thể chạy đồng thời thực sự trong một chương trình. Trên CPU multi-core, giá trị trả về của `hardware_concurrency()` tương ứng với số lõi CPU. Lưu ý, giá trị này chỉ là một gợi ý, và hàm có thể trả về 0 nếu thông tin không khả dụng.

Ví dụ sau đây sử dụng thông tin của hàm `hardware_concurrency()` để khởi tạo số thread sẽ sử dụng, nó tránh việc chạy quá nhiều thread trên phần cứng hạn chế:
```cpp
template <typename Iterator, typename T>
struct accumulate_block
{
    void operator()(Iterator first, Iterator last, T &result)
    {
        result = std::accumulate(first, last, result);
    }
};
template <typename Iterator, typename T>
T parallel_accumulate(Iterator first, Iterator last, T init)
{
    unsigned long const length = std::distance(first, last);
    if (!length) return init;

    unsigned long const min_per_thread = 25;
    unsigned long const max_threads = (length + min_per_thread - 1) / min_per_thread;
    unsigned long const hardware_threads = std::thread::hardware_concurrency();
    unsigned long const num_threads = std::min((hardware_threads!=0)?hardware_threads:2, max_threads);
    unsigned long const block_size = length / num_threads;

    std::vector<T> results(num_threads);
    std::vector<std::thread> threads(num_threads - 1);
    Iterator block_start = first;

    for (unsigned long i = 0; i < (num_threads - 1); ++i)
    {
        Iterator block_end = block_start;
        std::advance(block_end, block_size);
        threads[i] = std::thread(accumulate_block<Iterator, T>(), block_start, block_end, std::ref(results[i]));
        block_start = block_end;
    }
    accumulate_block<Iterator, T>()(block_start, last, results[num_threads - 1]);

    for (auto &entry: threads)
        entry.join();
    return std::accumulate(results.begin(), results.end(), init);
}
```

Giải thích ngắn gọn ví dụ trên:
- Hàm `parallel_accumulate()` này tính tổng các phần tử trong một khoảng sử dụng nhiều thread để cải thiện hiệu suất.
- `accumulate_block` là task được chia nhỏ để xử lý bởi các thread riêng.
- Số thread được khởi tạo phụ thuộc vào số lượng phần tử và số `hardware_concurrency()` trả về.
- Sau khi các thread hoàn thành việc tính toán, kết quả được tổng hợp lại bằng [std::accumulate](https://en.cppreference.com/w/cpp/algorithm/accumulate).

## 5. Cách nhận diện các thread

Nhận diện các thread bằng định danh thread `std::thread::id`, có thể lấy định danh thread bằng `std::this_thread::get_id()` hoặc lấy từ thread instance `<instance>.get_id()`. Ví dụ:
```cpp
#include <iostream>
#include <thread>
void hello()
{
    std::cout << "[FUNC] hello() thread id:" << std::this_thread::get_id() << std::endl;
}
int main()
{
    std::thread t(hello);
    std::cout << "[MAIN] hello() thread id:" << t.get_id() << std::endl;
    std::cout << "[MAIN] main() thread id:" << std::this_thread::get_id() << std::endl;
    t.join();
}
```

Các đối tượng `std::thread::id` cung cấp đầy đủ các toán tử so sánh, nên có thể dùng định danh thread để kiểm tra và xác định thread nào thực hiện task nào, hoặc dùng nó để gỡ lỗi, ghi nhật ký...
```cpp
std::thread::id master_thread;
void some_core_part_of_algorithm()
{
    if (std::this_thread::get_id() == master_thread)
    {
        do_master_thread_work();
    }
    do_common_work();
}
```

## 6. Tài liệu tham khảo

- [1] Anthony Williams, "2. Managing threads" in *C++ Concurrency in Action*, 2nd Edition, 2019.

## 7. Chú thích

[^fn-RAII]: RAII - Resource Acquisition Is Initialization.
[^fn-fire-and-forget]: Tác vụ kiểu fire-and-forget là các tác vụ được khởi chạy và sau đó không cần phải chờ đợi hoặc quan tâm tới kết quả, nó thường được sử dụng để xử lý các tác vụ không quan trọng và không làm gián đoạn luồng chính của chương trình.
[^fn-Parameter-vs-Argument]: Chú ý thuật ngữ *parameter* (tham số) và *argument* (đối số) là khác nhau, *parameter* là biến được khai báo trong một hàm, còn *argument* là giá trị thực tế của biến để truyền vào hàm. Tham khảo thêm [tại đây](https://stackoverflow.com/questions/156767/whats-the-difference-between-an-argument-and-a-parameter).
[^fn-instance]: Instance(s) trong lập trình hướng đối tượng là một hiện thực hóa cụ thể của bất kỳ object nào. Ví dụ: `std::thread t1;` thì `std::thread` là object và `t1` là instance.
