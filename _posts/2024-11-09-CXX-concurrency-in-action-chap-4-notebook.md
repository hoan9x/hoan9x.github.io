---
title: "Chương 4: Synchronizing concurrent operations"
description: Ghi chép trong quá trình đọc cuốn sách C++ Concurrency in Action của Anthony Williams
author: hoan9x
date: 2024-11-08 10:00:00 +0700
categories: [CXX, Multi-Threading]
mermaid: true
---

> Bài viết này vẫn chưa hoàn thiện.
{: .prompt-warning }

Chương này đề cập tới:
- Chờ đợi một sự kiện.
- Chờ đợi sự kiện một lần với futures.
- Chờ đợi trong giới hạn thời gian.
- Đồng bộ các thao tác để đơn giản hóa mã nguồn.

## 1. Chờ đợi một sự kiện hoặc điều kiện

Giả sử bạn đang đi tàu hỏa vào ban đêm, và bạn không muốn lỡ ga. Một cách là thức suốt đêm và chú ý các điểm dừng, nhưng sẽ rất mệt. Cách khác là xem lịch trình, đặt đồng hồ báo thức và ngủ, nhưng nếu tàu trễ, bạn vẫn sẽ bị thức sớm hơn. Lý tưởng nhất là có ai đó hoặc một thiết bị đánh thức bạn khi tàu đến đúng ga.

Tương tự, trong lập trình với threads, nếu muốn thread_a chờ cho thread_b hoàn thành task, có vài cách thực hiện. Một cách là cho thread_a kiểm tra liên tục một flag (là biến được chia sẻ giữa 2 threads), nhưng cách này lãng phí tài nguyên vì thread chờ là thread_a luôn chạy và kiểm tra flag, làm tốn tài nguyên CPU và giảm hiệu suất.

Cải tiến hơn là để thread_a chờ ngủ trong khoảng thời gian ngắn giữa các lần kiểm tra.
```cpp
bool flag;
std::mutex m;
void wait_for_flag()
{
    std::unique_lock<std::mutex> lk(m);
    while(!flag)
    {
        lk.unlock();
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
        lk.lock();
    }
}
```
Tuy nhiên, nếu thời gian ngủ quá ngắn hoặc quá dài, thread vẫn có thể lãng phí tài nguyên hoặc bị trễ khi task trên thread_b đã hoàn thành.

Cách tốt nhất là sử dụng *condition variable* (biến điều kiện) do C++ cung cấp để chờ đợi sự kiện. Khi một thread xác định điều kiện đã thỏa mãn, nó có thể notify (thông báo) cho các thread chờ để chúng tiếp tục xử lý mà không gây lãng phí tài nguyên.

### 1.1. Chờ đợi một sự kiện với condition variables

Thư viện chuẩn C++ cung cấp hai triển khai *condition variables* là `std::condition_variable` và `std::condition_variable_any`. Cả hai đều yêu cầu làm việc với một mutex để đảm bảo đồng bộ hóa, nhưng `std::condition_variable` chỉ làm việc với `std::unique_lock<std::mutex>`, trong khi `std::condition_variable_any` có thể làm việc với bất kỳ đối tượng nào đáp ứng *mutex-like* (nghĩa là đối tượng có `lock()` và `unlock()` để gọi). Tuy nhiên, `std::condition_variable_any` có thể gây chi phí thêm về kích thước và hiệu suất, nên `std::condition_variable` nên được ưu tiên sử dụng.

Mã ví dụ sử dụng `std::condition_variable`:
```cpp
std::mutex mut;
std::queue<data_chunk> data_queue;
std::condition_variable data_cond;
void data_preparation_thread()
{
    while (more_data_to_prepare())
    {
        data_chunk const data = prepare_data();
        {
            std::lock_guard<std::mutex> lk(mut);
            data_queue.push(data);
        }
        data_cond.notify_one();
    }
}
void data_processing_thread()
{
    while (true)
    {
        std::unique_lock<std::mutex> lk(mut);
        data_cond.wait(lk, []{ return !data_queue.empty(); });
        data_chunk data = data_queue.front();
        data_queue.pop();
        lk.unlock();
        process(data);
        if (is_last_chunk(data)) break;
    }
}
```
Trong ví dụ trên, có một queue (hàng đợi) dùng để truyền dữ liệu giữa hai thread. Khi dữ liệu sẵn sàng, thread chuẩn bị dữ liệu sẽ khóa mutex bảo vệ hàng đợi bằng `std::lock_guard` và thêm dữ liệu vào hàng đợi, sau đó gọi `notify_one()` để thông báo cho thread đang chờ. **Lưu ý rằng việc thông báo nên được thực hiện sau khi khóa mutex được giải phóng, tránh việc thread chờ lại phải đợi thêm**.

Thread xử lý dữ liệu sẽ khóa mutex với `std::unique_lock`, và gọi `wait()` với một hàm lambda kiểm tra điều kiện. Nếu điều kiện `!data_queue.empty()` trả về `false` (không thỏa mãn), `wait()` sẽ giải phóng mutex và làm thread vào trạng thái chờ. Khi có thông báo từ `notify_one()`, thread sẽ tỉnh dậy, kiểm tra lại điều kiện và chỉ khi `!data_queue.empty()` trả về `true` thì nó mới tiếp tục xử lý. Việc sử dụng `std::unique_lock` là cần thiết vì nó cho phép giải phóng và khóa lại mutex khi cần.

Thật ra, `std::condition_variable::wait` là một cách chờ được **tối ưu hóa** so với cách chờ bận rộn (busy-wait). Đây là cách chờ busy-wait ví dụ:
```cpp
template <typename Predicate>
void minimal_busy_wait(std::unique_lock<std::mutex> &lk, Predicate pred)
{
    while (!pred())
    {
        lk.unlock();
        lk.lock();
    }
}
```

### 1.2. Tạo một class thread-safe queue dùng condition variables

Xem xét `std::queue` interface sau:
```cpp
template <class T, class Container = std::deque<T>>
class queue
{
public:
    explicit queue(const Container &);
    explicit queue(Container && = Container());
    template <class Alloc> explicit queue(const Alloc &);
    template <class Alloc> queue(const Container &, const Alloc &);
    template <class Alloc> queue(Container &&, const Alloc &);
    template <class Alloc> queue(queue &&, const Alloc &);

    void swap(queue &q);
    bool empty() const;
    size_type size() const;
    T &front();
    const T &front() const;
    T &back();
    const T &back() const;
    void push(const T &x);
    void push(T &&x);
    void pop();
    template <class... Args>
    void emplace(Args &&...args);
};
```

Thiết kế lại thành các interface thread-safe như vầy:
```cpp
template <typename T>
class threadsafe_queue
{
public:
    threadsafe_queue();
    threadsafe_queue(const threadsafe_queue &);
    /* Disallow assignment for simplicity */
    threadsafe_queue &operator=(const threadsafe_queue &) = delete;

    void push(T new_value);
    bool try_pop(T &value);
    std::shared_ptr<T> try_pop();
    void wait_and_pop(T &value);
    std::shared_ptr<T> wait_and_pop();
    bool empty() const;
};
```
Tham khảo mục [2.3. Phát hiện race conditions trong interface](/posts/CXX-concurrency-in-action-chap-3-notebook/#23-ph%C3%A1t-hi%E1%BB%87n-race-conditions-trong-interface) của chương 3 để hiểu tại sao lại thiết kế interface như trên.

Triển khai của `threadsafe_queue` có tính năng mới là `wait_and_pop()` sẽ dùng `std::condition_variable` để chờ sự kiện `push()` khi queue đang trống:
```cpp
#include <queue>
#include <memory>
#include <mutex>
#include <condition_variable>
template <typename T>
class threadsafe_queue
{
private:
    mutable std::mutex mut;
    std::queue<T> data_queue;
    std::condition_variable data_cond;
public:
    threadsafe_queue() {}
    threadsafe_queue(threadsafe_queue const &other)
    {
        std::lock_guard<std::mutex> lk(other.mut);
        data_queue = other.data_queue;
    }
    void push(T new_value)
    {
        std::lock_guard<std::mutex> lk(mut);
        data_queue.push(new_value);
        data_cond.notify_one();
    }
    void wait_and_pop(T &value)
    {
        std::unique_lock<std::mutex> lk(mut);
        data_cond.wait(lk, [this]{ return !data_queue.empty(); });
        value = data_queue.front();
        data_queue.pop();
    }
    std::shared_ptr<T> wait_and_pop()
    {
        std::unique_lock<std::mutex> lk(mut);
        data_cond.wait(lk, [this]{ return !data_queue.empty(); });
        std::shared_ptr<T> res(std::make_shared<T>(data_queue.front()));
        data_queue.pop();
        return res;
    }
    bool try_pop(T &value)
    {
        std::lock_guard<std::mutex> lk(mut);
        if (data_queue.empty()) return false;
        value = data_queue.front();
        data_queue.pop();
        return true;
    }
    std::shared_ptr<T> try_pop()
    {
        std::lock_guard<std::mutex> lk(mut);
        if (data_queue.empty()) return std::shared_ptr<T>();
        std::shared_ptr<T> res(std::make_shared<T>(data_queue.front()));
        data_queue.pop();
        return res;
    }
    bool empty() const
    {
        std::lock_guard<std::mutex> lk(mut);
        return data_queue.empty();
    }
};
```

## 2. Chờ sự kiện one-off với futures

Sự kiện one-off là sự kiện chỉ diễn ra một lần. Thư viện chuẩn C++ mô phỏng sự kiện này bằng một khái niệm gọi là future. Nếu chỉ cần chờ một sự kiện duy nhất, hãy sử dụng future.

C++ cung cấp hai loại future: `std::future` và `std::shared_future`, ý tưởng tương tự như `std::unique_ptr` và `std::shared_ptr`. Các future này không tự động đồng bộ, nên nếu nhiều thread cần truy cập một future, phải sử dụng cơ chế đồng bộ như mutex. Hoặc có thể sử dụng bản sao riêng của `std::shared_future` mà không cần đồng bộ gì thêm.

### 2.1. Lấy kết quả trả về từ background tasks

Giả sử bạn có một phép tính cần thực hiện trong thời gian dài, nhưng hiện tại bạn chưa cần ngay kết quả. Bạn có thể sử dụng `std::thread` và `detach()` để chạy phép tính ở chế độ nền (background). Tuy nhiên, `std::thread` không hỗ trợ trực tiếp việc nhận giá trị trả về từ tác vụ chạy trong thread. Thay vào đó, sử dụng `std::async` sẽ phù hợp hơn, ví dụ:
```cpp
#include <future>
#include <iostream>
int find_the_answer();
void do_other_stuff();
int main()
{
    std::future<int> the_answer = std::async(find_the_answer);
    do_other_stuff();
    std::cout << "The answer is " << the_answer.get() << std::endl;
}
```
Trong ví dụ trên, tác vụ `find_the_answer()` có kiểu trả về là `int` và được đưa vào `std::async`. Đối tượng `std::async` tương tự như một thread chạy ở chế độ nền và trả về một future. Đối tượng `std::future` này lưu giữ giá trị trả về của tác vụ. Khi sử dụng `future_instance.get()`, thread hiện tại sẽ chờ cho đến khi tác vụ trong `std::async` hoàn tất và trả về dữ liệu.

Đối tượng `std::async` có cơ chế truyền đối số tương tự như `std::thread`, ví dụ:
```cpp
#include <string>
#include <future>
struct X
{
    void foo(int, std::string const &);
    std::string bar(std::string const &);
};
X x;
/* Calls p->foo(42,"hello") where p is &x */
auto f1 = std::async(&X::foo, &x, 42, "hello");
/* Calls tmpx.bar("goodbye") where tmpx is a copy of x */
auto f2 = std::async(&X::bar, x, "goodbye");
struct Y
{
    double operator()(double);
};
Y y;
/* Calls tmpy(3.141) where tmpy is move-constructed from Y() */
auto f3 = std::async(Y(), 3.141);
/* Calls y(2.718) */
auto f4 = std::async(std::ref(y), 2.718);
X baz(X &);
/* Calls baz(x) */
std::async(baz, std::ref(x));
class move_only
{
public:
    move_only();
    move_only(move_only &&)
    move_only(move_only const &) = delete;
    move_only &operator=(move_only &&);
    move_only &operator=(move_only const &) = delete;
    void operator()();
};
/* Calls tmp() where tmp is constructed from std::move(move_only()) */
auto f5 = std::async(move_only());
```

Ngoài ra, bạn có chỉ định cách `std::async` được khởi chạy bằng cách bổ sung tham số kiểu `std::launch`:
```cpp
auto f6 = std::async(std::launch::async, Y(), 1.2);  // Run in new thread
auto f7 = std::async(std::launch::deferred, baz, std::ref(x));  // Run when f7.wait() or f7.get() is called
auto f8 = std::async(std::launch::deferred | std::launch::async, baz, std::ref(x));  // Implementation chooses
auto f9 = std::async(baz, std::ref(x));  // Implementation chooses
f7.wait();  // Invoke deferred function
```

Tham số `std::launch` có thể nhận một trong các giá trị sau:
- `std::launch::deferred`: Chỉ định rằng task sẽ bị hoãn lại (deferred) cho đến khi `wait()` hoặc `get()` được gọi trên future.
- `std::launch::async`: Chỉ định rằng task phải được chạy ngay trên một thread mới.
- `std::launch::deferred | std::launch::async`: Chỉ định hệ thống tự động chọn (implementation chooses), hệ thống sẽ dựa vào tài nguyên, mức độ ưu tiên của task, hoặc các yếu tố như tải CPU để chọn một trong hai tùy chọn `std::launch::deferred` hoặc `std::launch::async`.

Nếu không đặt tham số `std::launch` cho `std::async` thì mặc định nó sẽ chỉ định là implementation chooses. Lưu ý, với `std::launch::deferred` nếu bạn không gọi `get()` hoặc `wait()` sau đó, task có thể sẽ không bao giờ được khởi chạy.

### 2.2. Liên kết task với đối tượng future

`std::packaged_task` là một cách để liên kết task (một hàm hoặc đối tượng callable) với một future. Đối tượng `std::packaged_task` là một đối tượng callable, vì vậy nó có thể được truyền cho một `std::thread` hoặc có thể gọi nó trực tiếp như hàm. Khi `std::packaged_task` được gọi, các đối số truyền vào sẽ được chuyển tiếp đến task chứa trong `std::packaged_task`, và giá trị trả về sẽ được lưu trữ trong đối tượng `std::future` mà bạn có thể lấy từ `get_future()`. Điều này rất hữu ích cho việc phát triển các hệ thống quản lý tác vụ (như ThreadPool).

## 3. Tài liệu tham khảo

- [1] Anthony Williams, "4. Synchronizing concurrent operations" in *C++ Concurrency in Action*, 2nd Edition, 2019.
