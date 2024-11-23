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

## 1. Chờ đợi một sự kiện

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
{: #refer-launch-deferred }

Tham số `std::launch` có thể nhận một trong các giá trị sau:
- `std::launch::deferred`: Chỉ định rằng task sẽ bị hoãn lại (deferred) cho đến khi `wait()` hoặc `get()` được gọi trên future.
- `std::launch::async`: Chỉ định rằng task phải được chạy ngay trên một thread mới.
- `std::launch::deferred | std::launch::async`: Chỉ định hệ thống tự động chọn (implementation chooses), hệ thống sẽ dựa vào tài nguyên, mức độ ưu tiên của task, hoặc các yếu tố như tải CPU để chọn một trong hai tùy chọn `std::launch::deferred` hoặc `std::launch::async`.

Nếu không đặt tham số `std::launch` cho `std::async` thì mặc định nó sẽ chỉ định là implementation chooses. Lưu ý, với `std::launch::deferred` nếu bạn không gọi `get()` hoặc `wait()` sau đó, task có thể sẽ không bao giờ được khởi chạy.

### 2.2. Liên kết task với đối tượng future

`std::packaged_task` là một cách để liên kết task với một future. Hay nói cách khác, `std::packaged_task` có thể bao bọc các kiểu callable thông thường (hàm, biểu thức lambda, biểu thức bind...) thành kiểu callable có thể trả về `std::future`. Ví dụ:
```cpp
#include <functional>
#include <future>
#include <iostream>
#include <thread>

int sum(int x, int y)
{
    std::cout << "thread_id sum() is " << std::this_thread::get_id() << std::endl;
    return x+y;
}

void task_lambda()
{
    std::packaged_task<int(int, int)> task([](int a, int b)
    {
        return a+b; 
    });
    std::future<int> result = task.get_future();

    task(2, 9);
    std::cout << "task_lambda " << result.get() << std::endl;
}
void task_bind()
{
    std::packaged_task<int()> task(std::bind(sum, 2, 11));
    std::future<int> result = task.get_future();

    task(); 
    std::cout << "task_bind " << result.get() << std::endl;
}
void task_thread()
{
    std::packaged_task<int(int, int)> task(sum);
    std::future<int> result = task.get_future();

    std::thread task_thread(std::move(task), 2, 10);
    task_thread.join();

    std::cout << "task_thread " << result.get() << std::endl;
}

int main()
{
    std::cout << "thread_id main() is " << std::this_thread::get_id() << std::endl;
    task_lambda();
    task_bind();
    task_thread();
}
```

Một cách hữu ích để sử dụng `std::packaged_task` là để passing tasks giữa các thread. Ví dụ, nhiều framework GUI yêu cầu các cập nhật GUI chỉ được thực hiện từ một thread cụ thể. Nếu một thread khác cần cập nhật GUI, nó phải gửi một tác vụ đến thread GUI. `std::packaged_task` có thể thực hiện điều này một cách dễ dàng:
```cpp
#include <deque>
#include <mutex>
#include <future>
#include <thread>
#include <utility>

std::mutex m;
std::deque<std::packaged_task<void()>> tasks;

bool gui_shutdown_message_received();
void get_and_process_gui_message();

void gui_thread()
{
    while (!gui_shutdown_message_received())
    {
        get_and_process_gui_message();
        std::packaged_task<void()> task;
        {
            std::lock_guard<std::mutex> lk(m);
            if (tasks.empty())
                continue;
            task = std::move(tasks.front());
            tasks.pop_front();
        }
        task();
    }
}

std::thread gui_bg_thread(gui_thread);

template <typename Func>
std::future<void> post_task_for_gui_thread(Func f)
{
    std::packaged_task<void()> task(f);
    std::future<void> res = task.get_future();
    std::lock_guard<std::mutex> lk(m);
    tasks.push_back(std::move(task));
    return res;
}
```
Giải thích
- Nhiệm vụ của `gui_thread()`:
  + Chạy vòng lặp đến khi nhận thông báo shutdown GUI.
  + Lần lượt xử lý các thông điệp GUI và kiểm tra hàng đợi `tasks`.
  + Nếu có `tasks`, lấy nó ra và thực thi.
  + Khi hoàn thành task, giá trị trả về `std::future` sẽ sẵn sàng.
- Nhiệm vụ của `post_task_for_gui_thread()`:
  + Tạo một `std::packaged_task<void()>` từ tham số callable `f`.
  + Lấy future `res` từ `get_future()`, thêm task vào hàng đợi, và trả future `res` về caller.
  + Caller có thể chờ future để biết khi nào task hoàn tất, hoặc bỏ qua nếu không cần kết quả.

### 2.3. Dùng std::promise tạo std::future

Trong lập trình, có những nhiệm vụ phức tạp không thể biểu diễn đơn giản bằng một lời gọi hàm, hoặc khi kết quả của nhiệm vụ phải được tổng hợp từ nhiều nguồn khác nhau. Trong trường hợp này, bạn có thể sử dụng `std::promise` để tạo `std::future`, nó cho phép đặt giá trị hoặc trạng thái lỗi một cách tường minh, giúp các thread giao tiếp hiệu quả.

Ví dụ khi xử lý nhiều kết nối mạng, ban đầu bạn có thể sử dụng mỗi thread cho một kết nối, cách này dễ lập trình và dễ hiểu khi số lượng kết nối ít. Tuy nhiên, nếu số lượng kết nối tăng lên, cách này sẽ gây tốn tài nguyên, giảm hiệu suất (do thực hiện quá nhiều context switching). Vì vậy, cách tốt hơn là dùng ít thread (thậm chí là chỉ một) để xử lý nhiều kết nối cùng lúc. Một thread có thể vừa nhận vừa gửi dữ liệu cho nhiều kết nối bằng cách sử dụng `std::promise` và `std::future` như mã minh họa:
```cpp
#include <future>
void process_connections(connection_set &conns)
{
    while (!done(conns))
    {
        for (auto conn = conns.begin(); conn != conns.end(); ++conn)
        {
            if (conn->has_incoming_data())
            {
                data_packet data = conn->incoming();
                std::promise<payload_type> &p = conn->get_promise(data.id);
                p.set_value(data.payload);
            }
            if (conn->has_outgoing_data())
            {
                outgoing_packet data = conn->top_of_outgoing_queue();
                conn->send(data.payload);
                data.promise.set_value(true);
            }
        }
    }
}
```
Mã minh họa trên lặp qua các kết nối để kiểm tra:
- Dữ liệu đến:
  + Lấy `data` gồm ID và payload từ connection.
  + Dùng ID để ánh xạ tới `std::promise`.
  + Lưu payload vào `std::promise` để thread khác nhận qua `std::future`.
- Dữ liệu đi:
  + Lấy `data` từ queue để gửi.
  + Đặt `true` vào `std::promise` để báo gửi thành công.

Tóm lại, cặp `std::promise` và `std::future` giúp thread giao tiếp dễ dàng hơn với:
- `std::promise`: Đặt giá trị (hoặc thông báo lỗi) để thread khác nhận qua `std::future`.
- `std::future`: Dùng để chờ và lấy kết quả từ `std::promise`.

### 2.4. Quản lý exception với std::future

Ta có một hàm `square_root()` sẽ ném exception khi truyền `-1` vào:
```cpp
double square_root(double x)  
{
    if (x < 0)  
    {  
        throw std::out_of_range("x < 0");  
    }  
    return sqrt(x);  
}
```

Bây giờ gọi `square_root()` dưới dạng `std::async`:
```cpp
std::future<double> f = std::async(square_root, -1);  
double y = f.get();
```

Khi một hàm được gọi bằng `std::async` mà ném ra một ngoại lệ, ngoại lệ này sẽ được lưu trong đối tượng `future` thay vì giá trị trả về (nghĩa là khi gọi `get()` trên `future`, ngoại lệ sẽ được ném lại). Với `std::packaged_task` cũng hoạt động tương tự. Lưu ý: Chuẩn C++ không quy định rõ ngoại lệ được ném lại là đối tượng gốc hay bản sao, điều này phụ thuộc vào trình biên dịch và thư viện sử dụng.

Với `std::promise` thì cho phép đặt ngoại lệ rõ ràng bằng cách gọi `set_exception()` thay vì `set_value()`:
```cpp
extern std::promise<double> some_promise;  
try
{
    some_promise.set_value(calculate_value());  
}
catch(...)
{
    some_promise.set_exception(std::current_exception());  
}
```
Ở đây, `std::current_exception()` được sử dụng để lấy ngoại lệ đã bị ném của `try{}` nếu có.

Ngoài ra, bạn có thể sử dụng `std::make_exception_ptr()` để lưu trực tiếp một ngoại lệ mới:
```cpp
some_promise.set_exception(std::make_exception_ptr(std::logic_error("foo")));
```

Ngoại lệ thất hứa (broken_promise): Nếu `std::promise` hoặc `std::packaged_task` bị hủy mà không gọi hàm `set_value()` hoặc `set_exception()`, destructor của chúng sẽ ném một ngoại lệ `std::future_error` với mã lỗi `std::future_errc::broken_promise`. Điều này đảm bảo các thread chờ `future` không bị kẹt vĩnh viễn, ví dụ:
```cpp
void worker(std::future<int> fut)
{
    try
    {
        int value = fut.get();
        std::cout << "Received value: " << value << '\n';
    }
    catch (const std::future_error &e)
    {
        std::cout << "Caught exception: " << e.what() << ")\n";
    }
}
void broken_promise()
{
    std::promise<int> prom;
    std::future<int> fut = prom.get_future();
    std::thread t(worker, std::move(fut));
    /* Destroy the promise without calling set_value() or set_exception() */
    prom.~promise();
    t.join();
}
void broken_promise_with_packaged_task()
{
    std::packaged_task<int()> task([]()
    {
        return 42;
    });
    std::future<int> fut = task.get_future();
    std::thread t(worker, std::move(fut));
    /* Destroy packaged_task without executing the task (this means the future has no return value) */
    task.~packaged_task();
    t.join();
}
```

### 2.5. Chờ đợi từ nhiều threads

Mặc dù `std::future` xử lý đồng bộ hóa cần thiết khi chuyển dữ liệu giữa các thread, nhưng nó không đồng bộ hóa các cuộc gọi hàm thành viên của chính nó. Vì vậy, nếu nhiều thread truy cập vào một `std::future` mà không có cơ chế đồng bộ, sẽ xảy ra race condition. Để cho phép nhiều thread chờ cùng một sự kiện mà không gặp vấn đề này, ta nên sử dụng `std::shared_future`. `std::shared_future` cho phép sao chép, do đó nhiều thread có thể có bản sao riêng, giúp tránh race condition.

`std::shared_future` có thể được tạo bằng cách `std::move` một `std::future`:
```cpp
std::promise<int> p;
std::future<int> f(p.get_future()); // The future f is valid
std::shared_future<int> sf(std::move(f)); // f is no longer valid, and sf is now valid
```

`std::shared_future` cũng có thể được chuyển đổi ngầm định từ `std::future`:
```cpp
std::promise<std::string> p;
std::shared_future<std::string> sf(p.get_future()); // Implicit transfer of ownership
```

Gọi hàm thành viên `share()` của `std::future` sẽ trả về một `std::shared_future`:
```cpp
std::promise<std::map<SomeIndexType,SomeDataType,SomeComparator,SomeAllocator>::iterator> p;
auto sf = p.get_future().share(); 
```

## 3. Chờ đợi trong giới hạn thời gian

### 3.1. Giới thiệu về clock

Thư viện chuẩn C++ `<chrono>` cung cấp ba clock chính:
- `std::chrono::system_clock`: Đại diện cho đồng hồ thời gian thực (real-time clock) của hệ thống.
- `std::chrono::steady_clock`: Đảm bảo tick đều đặn, hữu ích trong tính toán timeout.
- `std::chrono::high_resolution_clock`: Cung cấp chu kỳ tick nhỏ nhất (độ phân giải cao nhất).

Ta có thể nói clock là nguồn thông tin về thời gian, một clock sẽ cung cấp:
- Thời gian hiện tại `now()`, ví dụ `std::chrono::system_clock::now()` trả về thời gian hiện tại hệ thống.
- Kiểu dữ liệu thời điểm `time_point` do clock trả về, ví dụ `xxx_clock::now()` trả về` xxx_clock::time_point`.
- Chu kỳ tick `period` biểu diễn bằng phân số giây, ví dụ: clock tick 25 lần/giây có period là `std::ratio<1,25>`. Nếu chu kỳ tick không cố định hoặc thay đổi trong runtime, chu kỳ này có thể được ước tính (tùy thư viện quy định).
- Tính đều đặn `steady`, xác định bởi `is_steady`. Giá trị `is_steady` của clock là `true` thì clock phải tick đều đặn và không điều chỉnh được. Ví dụ, `std::chrono::steady_clock` là `steady`, còn `std::chrono::system_clock` không phải vì có thể bị điều chỉnh để bù độ lệch thời gian, dẫn đến giá trị `now()` có thể bị giảm giữa hai lần gọi.

### 3.2. Giới thiệu về durations

Durations (khoảng thời gian) được biểu diễn bởi class template `std::chrono::duration<>`. Nó có 2 tham số cho template:
- Tham số đầu tiên: Kiểu dữ liệu đại diện, như `int`, `long`, `double`.
- Tham số thứ hai: Chu kỳ tick biểu diễn bao nhiêu giây mỗi đơn vị duration.

Ví dụ:
- `std::chrono::duration<short, std::ratio<60,1>>` là số minutes vì có (60/1)s mỗi đơn vị.
- `std::chrono::duration<double, std::ratio<1,1000>>` là số milliseconds vì có (1/1000)s mỗi đơn vị.

Thư viện chuẩn C++ có các kiểu durations được định nghĩa sẵn trong namespace `std::chrono` như: `nanoseconds`, `microseconds`, `milliseconds`, `seconds`, `minutes`, và `hours`. Ví dụ `duration1` và `duration2` là tương đương nhau với mã bên dưới:
```cpp
auto duration1 = std::chrono::milliseconds(10);
auto duration2 = std::chrono::duration<int64_t, std::ratio<1,1000>>(10);
```

Với namespace `std::chrono_literals` (C++14 trở đi), ta có thể tạo các durations dễ hơn bằng hậu tố:
```cpp
using namespace std::chrono_literals;
auto one_day = 24h; /* same as std::chrono::hours(24) */
auto half_hour = 30min; /* same as std::chrono::minutes(30) */
auto delay = 30ms; /* same as std::chrono::milliseconds(30) */
```

Chuyển đổi duration:
- Chuyển đổi tự động: Chỉ xảy ra khi không bị mất mát dữ liệu (ví dụ từ `seconds` sang `milliseconds`).
- Chuyển đổi rõ ràng: Dùng `std::chrono::duration_cast<>`, ví dụ:
```cpp
std::chrono::milliseconds ms(54802);
std::chrono::seconds s = std::chrono::duration_cast<std::chrono::seconds>(ms);
/* Result: s=54s. Because the value (ms) is truncated */
```

Durations cũng có hỗ trợ các phép toán, ví dụ:
```cpp
auto five_seconds = 5*std::chrono::seconds(1);
auto result = std::chrono::minutes(1)-std::chrono::seconds(55); // 5s
```

Có thể dùng `count()` để lấy giá trị số của durations, ví dụ:
```cpp
std::chrono::milliseconds(1234).count(); // Result: 1234
```

Sử dụng durations trong các hàm chờ như `wait_for()` hoặc `wait_until()`, ví dụ:
```cpp
std::future<int> f = std::async(some_task);
if (std::future_status::ready == f.wait_for(std::chrono::milliseconds(35)))
{
    do_something_with(f.get());
}
```
Giá trị trả về của future khi dùng `wait_for()` bao gồm:
- `std::future_status::timeout`: Quá thời gian chờ.
- `std::future_status::ready`: Kết quả sẵn sàng.
- `std::future_status::deferred`: Loại khởi chạy task của `std::async` là [deferred](#refer-launch-deferred).

### 3.3. Giới thiệu về time points

Time points (thời điểm) được biểu diễn bởi class template `std::chrono::time_point<>`. Nó có 2 tham số cho template:
- Tham số đầu tiên: Chỉ định loại clock mà time point tham chiếu.
- Tham số thứ hai: Đơn vị đo lường thời gian (kiểu durations được định nghĩa sẵn).

Giá trị của time point là duration (khoảng thời gian) kể từ một thời điểm gốc gọi là epoch của clock.

![light mode only][img_1]{: width="663" height="172" .light }
![dark mode only][img_1d]{: width="663" height="172" .dark }

Epoch là thuộc tính cơ bản của clock nhưng không được định nghĩa cụ thể trong tiêu chuẩn C++ và không thể truy xuất trực tiếp. Thông thường, epoch có thể là lúc 00:00 ngày 1/1/1970 hoặc thời điểm mà máy tính hoặc chương trình khởi động. Dù không thể biết chính xác epoch, nhưng bạn có thể sử dụng `time_since_epoch()` để lấy duration từ epoch đến một time point cụ thể, ví dụ:
```cpp
std::chrono::time_point<std::chrono::system_clock, std::chrono::milliseconds> tp;
auto result = tp.time_since_epoch();
```
Vì milliseconds được đặt làm đơn vị đo lường thời gian của time point (tham số thứ hai cho template), nên kiểu dữ liệu `result` của ví dụ trên sẽ là duration kiểu `std::chrono::milliseconds`

Ta có thể dùng time point cộng/trừ với một duration để tạo time point mới, và từ hai time point, ta có thể tính được thời gian thực thi của một đoạn mã. Ví dụ:
```cpp
auto future_time = std::chrono::high_resolution_clock::now() + std::chrono::nanoseconds(500);
auto start = std::chrono::high_resolution_clock::now();
do_something();
auto stop = std::chrono::high_resolution_clock::now();
std::cout << "do_something() took "
            << std::chrono::duration<double, std::chrono::seconds>(stop - start).count()
            << " seconds" << std::endl;
```

## 4. Tài liệu tham khảo

- [1] Anthony Williams, "4. Synchronizing concurrent operations" in *C++ Concurrency in Action*, 2nd Edition, 2019.

[//]: # (----------SCOPE OF DECLARATION OF LIST OF IMAGES USED IN POST----------)
[img_1]: /assets/img/2024-11-CXX-concurrency-chap-4/01_concept_of_duration_and_time_point.png "Khái niệm về duration, time point, và epoch"
[img_1d]: /assets/img/2024-11-CXX-concurrency-chap-4/01d_concept_of_duration_and_time_point.png "Khái niệm về duration, time point, và epoch"
