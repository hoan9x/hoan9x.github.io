---
title: "Chương 4: Synchronizing concurrent operations"
description: Ghi chép trong quá trình đọc cuốn sách C++ Concurrency in Action của Anthony Williams
author: hoan9x
date: 2024-11-08 10:00:00 +0700
categories: [CXX, Multi-Threading]
mermaid: true
---

Chương này đề cập tới:
- Chờ đợi một sự kiện.
- Chờ đợi sự kiện one-off với futures.
- Chờ đợi trong giới hạn thời gian.
- Đồng bộ hóa và tối ưu mã nguồn.

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

## 2. Chờ đợi sự kiện one-off với futures

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

Chú ý loại clock mà time point tham chiếu, vì nó sẽ ảnh hưởng đến hành vi của các hàm chờ `wait_until()`. Nguyên lý của hàm chờ `wait_until()` là nó sẽ không kết thúc cho đến khi `xxx_clock::now()` vượt qua giá trị timeout được chỉ định. Và nếu clock bị điều chỉnh trong thời gian chờ, thời gian chờ thực tế sẽ bị thay đổi. Ví dụ đoạn mã dưới đây cho thấy cách condition variable chờ trong giới hạn 500ms:
```cpp
#include <condition_variable>
#include <mutex>
#include <chrono>
std::condition_variable cv;
bool done;
std::mutex m;
bool wait_loop()
{
    auto const timeout = std::chrono::steady_clock::now() +
                         std::chrono::milliseconds(500);
    std::unique_lock<std::mutex> lk(m);
    while (!done)
    {
        if (cv.wait_until(lk, timeout) == std::cv_status::timeout)
            break;
    }
    return done;
}
```

### 3.4. Các hàm hỗ trợ timeout

Timeout cơ bản nhất được sử dụng để trì hoãn xử lý của một thread khi không có công việc, nhằm tránh ảnh hưởng đến hiệu suất của các thread khác. Hai hàm thường dùng là:
- `std::this_thread::sleep_for(duration)`: Tạm dừng thread trong một khoảng thời gian nhất định.
- `std::this_thread::sleep_until(time_point)`: Tạm dừng thread đến một thời điểm cụ thể.

Timeout còn được áp dụng trong các cơ chế chờ như condition variables, futures, và timed_mutex. Các hàm hỗ trợ timeout cho phép đồng bộ thread một cách hiệu quả hơn, đặc biệt trong các tình huống cần kiểm soát thời gian chờ cụ thể.

## 4. Đồng bộ hóa và tối ưu mã nguồn

### 4.1. Functional Programming với future

Thuật ngữ Functional Programming (FP) đề cập đến một phong cách lập trình trong đó kết quả của hàm chỉ phụ thuộc vào tham số truyền vào và không thay đổi trạng thái bên ngoài (vì tránh dùng shared data). Điều này giúp loại bỏ các vấn đề về race condition, dẫn đến không cần dùng mutex.

Từ C++11, việc viết mã theo phong cách FP sẽ trở nên dễ dàng hơn nhờ lambda function, `std::bind`, hỗ trợ suy diễn kiểu dữ liệu tự động, và cuối cùng là future, nhờ chúng mà ta có thể truyền kết quả giữa các thread mà không cần truy cập trực tiếp vào shared data.

Để minh họa việc sử dụng future theo phong cách FP, chúng ta sẽ xem xét một hàm đang lập trình cho thuật toán quick-sort:
```cpp
template <typename T>
std::list<T> sequential_quick_sort(std::list<T> input)
{
    if (input.empty())
    {
        return input;
    }
    std::list<T> result;
    result.splice(result.begin(), input, input.begin());
    T const &pivot = *result.begin();
    auto divide_point = std::partition(input.begin(), input.end(),
        [&](T const &t){ return t < pivot; });

    std::list<T> lower_part;
    lower_part.splice(lower_part.end(), input, input.begin(), divide_point);

    auto new_lower(sequential_quick_sort(std::move(lower_part)));
    auto new_higher(sequential_quick_sort(std::move(input)));

    result.splice(result.end(), new_higher);
    result.splice(result.begin(), new_lower);
    return result;
}
```
Giải thích:
- Dòng 9: Dùng `splice()` để ghép item.begin() của `input` list vào `result` list (`splice()` sẽ chỉ gán lại các con trỏ của item bên trong list chứ không copy/move item).
- Dòng 10: Đặt item begin() làm trục (pivot) để thực hiện quick-sort.
    + Lưu ý 1: Việc lấy pivot đại như vầy có khả năng làm thuật toán quick-sort không tối ưu.
    + Lưu ý 2: Viết mã theo phong cách FP, bạn sẽ phải copy data khá nhiều, nên hãy cố gắng dùng reference/move nếu được để đỡ chi phí.
- Dòng 11: Dùng `std::partition` để phân chia item trong list của `input`, item `t` nào có `(t < pivot)==true` thì item đó được đứng trước list.
- Như vậy ta có thể có các list với các item được phân chia theo trục (pivot), tiếp tục dùng đệ quy cho đến hết. Thuật toán quick-sort trên có thể được mô tả như hình dưới, với giá trị pivot đầu tiên là 5:

![light mode only][img_2]{: width="850" height="440" .light }
![dark mode only][img_2d]{: width="850" height="440" .dark }

Hàm `sequential_quick_sort()` trên đã lập trình theo phong cách FP, nên ta có thể dễ dàng chuyển nó thành phiên bản chạy parallel với future:
```cpp
template <typename T>
std::list<T> parallel_quick_sort(std::list<T> input)
{
    if (input.empty())
    {
        return input;
    }
    std::list<T> result;
    result.splice(result.begin(), input, input.begin());
    T const &pivot = *result.begin();
    auto divide_point = std::partition(input.begin(), input.end(),
        [&](T const &t){ return t < pivot; });

    std::list<T> lower_part;
    lower_part.splice(lower_part.end(), input, input.begin(), divide_point);

    std::future<std::list<T>> new_lower(std::async(&parallel_quick_sort<T>, std::move(lower_part)));
    auto new_higher(parallel_quick_sort(std::move(input)));

    result.splice(result.end(), new_higher);
    result.splice(result.begin(), new_lower.get());
    return result;
}
```
Hàm `parallel_quick_sort()` trên sử dụng `std::async()` để xử lý bất đồng bộ list `lower_part` trên thread riêng, trong khi phần list `new_higher` vẫn được xử lý đệ quy trên thread hiện tại. Mỗi lần đệ quy có thể tạo thêm thread mới, tận dụng khả năng xử lý đồng thời của phần cứng, và `std::async()` có thể tự động giới hạn số lượng thread để tránh quá tải (vì số lượng thread có thể tăng theo cấp số nhân khi quick-sort một list lớn).

Việc triển khai quick-sort parallel bằng `std::async()` như trên vẫn chưa phải là tối ưu, do `std::partition` vẫn là hàm xử lý tuần tự. Để có hiệu suất cao hơn, bạn phải tham khảo các tài liệu học thuật sâu hơn.

Ngoài FP, một phong cách lập trình khác là mô hình CSP (Communicating Sequential Processes) cũng tránh thay đổi shared data, thay vào đó, các thread giao tiếp bằng message passing (truyền tin nhắn). Mô hình này được áp dụng trong [Erlang](https://www.erlang.org/) và [MPI](https://www.mpi-forum.org/), phần tiếp theo sẽ trình bày cách triển khai mô hình này bằng C++.

### 4.2. Đồng bộ hóa với message passing

CSP (Communicating Sequential Processes) là một mô hình lập trình parallel, trong đó các thread hoặc process hoạt động độc lập và giao tiếp với nhau bằng message passing. Trong CSP, mỗi thread có thể được coi như một state machine: khi nhận được một message, nó sẽ cập nhật state của mình và có thể message passing tới các thread khác (việc xử lý này phụ thuộc vào state hiện tại của thread và nội dung message nhận được).

Mặc dù mô hình CSP gốc là không cho phép shared data giữa các thread, nhưng trong C++, các thread có chung một không gian địa chỉ, việc tuân thủ nguyên tắc không shared data đòi hỏi sự kỷ luật từ lập trình viên. Shared data duy nhất nên được chia sẻ giữa các thread là message queues (hàng đợi để truyền tin nhắn), và các hàng đợi này cần được đồng bộ hóa cẩn thận.

Một ứng dụng thực tiễn của CSP trong C++ là Actor Model, trong đó mỗi Actor là một thực thể độc lập (thường chạy trên một thread), xử lý thông điệp tuần tự và giao tiếp qua các message queue. Sau đây sẽ là một ví dụ về chương trình ATM được triển khai theo Actor Model.

Hệ thống ATM có thể được chia thành các thread độc lập như sau:
- Thread điều khiển phần cứng: Xử lý thẻ, hiển thị, bàn phím, xuất tiền.
- Thread logic ATM: Quản lý quy trình giao dịch.
- Thread giao tiếp tới ngân hàng: Gửi và nhận thông tin xác thực tài khoản.

Dưới đây là cách xây dựng thread logic ATM như một state machine:

![light mode only][img_3]{: width="850" height="600" .light }
![dark mode only][img_3d]{: width="850" height="600" .dark }

Triển khai đơn giản của thread logic ATM, các thread sẽ giao tiếp qua các message sender/receiver:
```cpp
struct card_inserted
{
    std::string account;
};
class atm
{
    messaging::receiver incoming;
    messaging::sender bank;
    messaging::sender interface_hardware;
    void (atm::*state)(); // function pointer to method of class atm
    std::string account;
    std::string pin;
    void waiting_for_card()
    {
        interface_hardware.send(display_enter_card());
        incoming.wait().handle<card_inserted>([&](card_inserted const &msg) {
            account = msg.account;
            pin = "";
            interface_hardware.send(display_enter_pin());
            state = &atm::getting_pin;
        });
    }
    void getting_pin();

public:
    void run()
    {
        state = &atm::waiting_for_card;
        try
        {
            for (;;)
            {
                (this->*state)();
            }
        }
        catch (messaging::close_queue const &) {}
    }
};
```
Con trỏ hàm `state` được trỏ tới hàm `waiting_for_card()`(dòng 28), hàm này hiển thị yêu cầu người dùng nhập thẻ (dòng 15), sau đó chờ thông điệp kiểu `card_inserted` (dòng 16). Khi nhận được thông điệp, tiến hành một số công việc, sau đó chuyển `state` tới `getting_pin()` (dòng 20).

```cpp
void atm::getting_pin()
{
    incoming.wait().handle<digit_pressed>([&](digit_pressed const &msg)
    {
            unsigned const pin_length = 4;
            pin += msg.digit;
            if (pin.length() == pin_length)
            {
                bank.send(verify_pin(account, pin, incoming));
                state = &atm::verifying_pin;
            }
    }).handle<clear_last_pressed>([&](clear_last_pressed const &msg)
        {
            if (!pin.empty())
            {
                pin.resize(pin.length() - 1);
            }
        }).handle<cancel_pressed>([&](cancel_pressed const &msg)
            {
                state = &atm::done_processing;
            });
}
```
Khi `state` là `getting_pin()`, chương trình sẽ chờ ba loại thông điệp:
- `digit_pressed`: Thêm ký tự vào `pin` mỗi lần nhập cho tới khi đủ ký tự thì chuyển `state` sang `verifying_pin()`.
- `clear_last_pressed`: Xóa ký tự vừa nhập.
- `cancel_pressed`: Hủy giao dịch thì chuyển `state` sang `done_processing()`

Ưu điểm của Actor Model (thực tiễn của mô hình CSP):
- Đơn giản hóa concurrency và tối ưu mã nguồn: Không cần lo về đồng bộ dữ liệu giữa các thread.
- Tách biệt nhiệm vụ rõ ràng: Mỗi thread chỉ cần xử lý logic của nó.
- Dễ mở rộng: Dựa vào message sender/receiver, bạn có thể thêm các tính năng hoặc thread xử lý mới mà không ảnh hưởng tới logic hiện tại.

### 4.3. Đồng thời với continuation-style

Future trong namespace `std::experimental::future` được mở rộng tính năng mới, nó cho phép bổ sung thêm các hành động tiếp theo khi kết quả của future sẵn sàng thông qua hàm `then()`, đây được gọi là continuation-style (kiểu tiếp nối).
```cpp
std::experimental::future<int> find_the_answer;
auto fut = find_the_answer();
auto fut2 = fut.then(find_the_question);
assert(!fut.valid()); // fut is invalid
assert(fut2.valid()); // fut2 is valid
```
Tương tự như `std::future`, `std::experimental::future` chỉ cho phép lấy giá trị đã lưu một lần, nên `fut` sẽ không còn hợp lệ. Vì khi dùng `fut.then()`, kết quả của `fut` đã được chuyển giao cho `fut2`. Và `find_the_question` trong `then()` là một hàm continuation sẽ được thực thi "trên một thread không xác định" (là thread do thư viện quản lý) khi future ban đầu sẵn sàng.

Hàm continuation nhận future đã sẵn sàng làm tham số duy nhất, cho phép xử lý cả kết quả và exception. Ví dụ `find_the_answer()` trả về `std::experimental::future<int>`, nên hàm continuation `find_the_question` sẽ có tham số duy nhất là `std::experimental::future<int>`.
```cpp
std::string find_the_question(std::experimental::future<int> the_answer);
```

Trong `std::experimental`, không có API tương đương `std::async` mà trả về `std::experimental::future`, nhưng có thể tự viết bằng cách dùng `std::experimental::promise` như sau:
```cpp
template<typename Func>
std::experimental::future<decltype(std::declval<Func>()())> spawn_async(Func&& func)
// spawn_async() return a future, and result type is the same as the return type of the Func function.
{
    std::experimental::promise<decltype(std::declval<Func>()())> p;
    auto res = p.get_future();
    std::thread t( [p = std::move(p), f = std::decay_t<Func>(func)]() mutable
    {
        try
        {
            // Try to execute the f() and sets the value of the promise
            p.set_value_at_thread_exit(f());
        }
        catch (...)
        {
            // If an exception is thrown, it's caught and set as the exception of the promise
            p.set_exception_at_thread_exit(std::current_exception());
        }
    });
    t.detach();
    return res;
}
```

### 4.4. Đồng thời với chuỗi continuations

Khi có một loạt tác vụ tốn thời gian, bạn muốn thực hiện chúng không đồng bộ để giải phóng main thread cho các nhiệm vụ khác. Ví dụ: khi người dùng đăng nhập vào ứng dụng, bạn cần:
- Gửi thông tin đăng nhập đến backend để xác thực.
- Khi xác thực xong, yêu cầu backend cung cấp thông tin tài khoản của người dùng.
- Sau khi nhận được thông tin tài khoản, cập nhật giao diện hiển thị.

Mã xử lý theo cách tuần tự:
```cpp
void process_login(std::string const &username, std::string const &password)
{
    try
    {
        user_id const id = backend.authenticate_user(username, password);
        user_data const info_to_display = backend.request_current_info(id);
        update_display(info_to_display);
    }
    catch (std::exception &e)
    {
        display_error(e);
    }
}
```

Mã xử lý với `std::async`:
```cpp
std::future<void> process_login(std::string const &username, std::string const &password)
{
    return std::async(std::launch::async, [=](){
        try
        {
            user_id const id = backend.authenticate_user(username, password);
            user_data const info_to_display = backend.request_current_info(id);
            update_display(info_to_display);
        }
        catch (std::exception& e)
        {
            display_error(e);
        }
    });
}
```
Cách xử lý với `std::async` vẫn tiêu tốn tài nguyên vì các thread sẽ bị chặn khi chờ các tác vụ hoàn thành.

Mã xử lý với chuỗi continuations:
```cpp
std::experimental::future<void> process_login(std::string const &username, std::string const &password)
{
    return spawn_async( [=]()
    {
        return backend.authenticate_user(username, password);
    }
    ).then([](std::experimental::future<user_id> id)
    {
        return backend.request_current_info(id.get());
    }
    ).then([](std::experimental::future<user_data> info_to_display)
    {
        try
        {
            update_display(info_to_display.get());
        }
        catch (std::exception& e)
        {
            display_error(e);
        }
    });
}
```

Ưu điểm của chuỗi continuations:
- Quản lý exception: Nếu bất kỳ phần nào trong chuỗi tác vụ phát sinh exception, nó sẽ được truyền tới phần tiếp theo. Ví dụ, khi `id.get()` hoặc `info_to_display.get()` phát sinh lỗi, đoạn mã cuối cùng có thể xử lý toàn bộ bằng `catch`.
- Future-unwrapping: Nếu một continuation trả về `future<future<T>>`, `then()` tự động "unwrap" giá trị để trả về `future<T>`. Điều này giúp mã ngắn gọn và dễ đọc hơn. Ví dụ: Không có future-unwrapping thì phải gọi `.get()` nhiều lần để truy xuất giá trị `auto result = fut.get().get();`. Còn có future-unwrapping thì chỉ cần gọi một lần `.get()` với chuỗi continuations.
- Không blocking thread: Các tác vụ được thực hiện không đồng bộ hoàn toàn, backend trả về future thay vì chặn thread khi chờ dữ liệu.

Ngoài ra, có thể sử dụng `std::experimental::shared_future` cho phép shared data cho nhiều hàm continuations cùng tham chiếu.
```cpp
auto fut = spawn_async(some_function).share();
auto fut2 = fut.then([](std::experimental::shared_future<some_data> data)
                     { do_stuff(data); });
auto fut3 = fut.then([](std::experimental::shared_future<some_data> data)
                     { return do_other_stuff(data); });
```
`fut` mã ví dụ trên là `shared_future`, cho phép `fut2` và `fut3` chia sẻ trạng thái mà không có race condition.

### 4.5. Chờ nhiều future cùng lúc

Khi cần xử lý một lượng lớn dữ liệu mà các phần tử có thể xử lý độc lập, bạn có thể tận dụng phần cứng bằng cách khởi chạy các tác vụ `std::async` để xử lý từng phần tử và trả về kết quả qua future, ví dụ:
```cpp
std::future<FinalResult> process_data(std::vector<MyData> &vec)
{
    size_t const chunk_size = whatever;
    std::vector<std::future<ChunkResult>> results;
    for (auto begin = vec.begin(), end = vec.end(); begin != end;)
    {
        size_t const remaining_size = end-begin;
        size_t const this_chunk_size = std::min(remaining_size, chunk_size);
        results.push_back(std::async(process_chunk, begin, begin+this_chunk_size));
        begin += this_chunk_size;
    }
    return std::async([all_results = std::move(results)]()
    {
        std::vector<ChunkResult> v;
        v.reserve(all_results.size());
        for (auto &f: all_results)
        {
            v.push_back(f.get()); // f.get() will block this thread until the data is ready
        }
        return gather_results(v);
    });
}
```
Trong đoạn code trên, mỗi lần đợi kết quả ở dòng 18, thread sẽ được scheduler đánh thức, xử lý kết quả, và lại ngủ để chờ future tiếp theo. Chờ nhiều future theo cách này tốn chi phí do context switching.

Cách tối ưu hơn nếu gặp trường hợp trên là sử dụng `std::experimental::when_all` để gom tất cả future lại và chờ đồng thời, tạo ra một future mới chỉ sẵn sàng khi tất cả các future con đều hoàn thành. Điều này giúp giảm tải hệ thống vì không cần xử lý từng future riêng lẻ, ví dụ:
```cpp
std::experimental::future<FinalResult> process_data(std::vector<MyData> &vec)
{
    size_t const chunk_size = whatever;
    std::vector<std::experimental::future<ChunkResult>> results;
    for (auto begin = vec.begin(), end = vec.end(); begin != end;)
    {
        size_t const remaining_size = end-begin;
        size_t const this_chunk_size = std::min(remaining_size, chunk_size);
        results.push_back(spawn_async(process_chunk, begin, begin+this_chunk_size));
        begin += this_chunk_size;
    }
    return std::experimental::when_all(results.begin(), results.end()).then( // Use when_all() to wait for all the futures to become ready
        [](std::experimental::future<std::vector<std::experimental::future<ChunkResult>>> ready_results)
        {
            auto all_results = ready_results.get();
            std::vector<ChunkResult> v;
            v.reserve(all_results.size());
            for (auto &f: all_results)
            {
                v.push_back(f.get()); // f.get() will no longer block this thread, because the data is ready
            }
            return gather_results(v);
        });
}
```
- Dòng 12: Sử dụng `when_all()` để tạo future tổng hợp, đợi tất cả các future con hoàn thành.
- Dòng 20: Các future con tại đây không còn block, vì toàn bộ giá trị đã sẵn sàng.

Bên cạnh `when_all()`, còn có `when_any()` để tạo một future sẵn sàng ngay khi một trong các future được cung cấp hoàn thành. Điều này hữu ích trong trường hợp bạn cần phản hồi ngay khi một tác vụ hoàn thành mà không phải đợi tất cả.

### 4.6. Chờ future đầu tiên hoàn thành với when_any

Giả sử bạn có một tập dữ liệu lớn, và bạn phải tìm một giá trị trong đó và nó phải thỏa mãn một tiêu chí nào đó. Bài toán này có thể song song hóa bằng cách:
- Chia dữ liệu thành các phần nhỏ, mỗi thread xử lý một phần.
- Khi thread đầu tiên tìm thấy kết quả, nó dừng các thread khác và trả về kết quả.

Nói cách khác, yêu cầu trên muốn bạn xử lý ngay khi có một tác vụ hoàn thành, dù các tác vụ khác có thể chưa kết thúc. `std::experimental::when_any` phù hợp để giải quyết vấn đề này, ví dụ:
```cpp
std::experimental::future<FinalResult> find_and_process_value(std::vector<MyData> &data)
{
    unsigned const concurrency = std::thread::hardware_concurrency();
    unsigned const num_tasks = (concurrency > 0) ? concurrency : 2;
    std::vector<std::experimental::future<MyData *>> results;
    auto const chunk_size = (data.size() + num_tasks - 1) / num_tasks;
    auto chunk_begin = data.begin();
    auto done_flag = std::make_shared<std::atomic<bool>>(false);

    for (unsigned i = 0; i < num_tasks; ++i)
    {
        auto chunk_end = (i < (num_tasks - 1)) ? chunk_begin + chunk_size : data.end();
        results.push_back(spawn_async([=]
        {
            for (auto entry = chunk_begin; !*done_flag && (entry != chunk_end); ++entry)
            {
                if (matches_find_criteria(*entry))
                {
                    *done_flag = true;
                    return &*entry;
                }
            }
            return (MyData *)nullptr;
        }));
        chunk_begin = chunk_end;
    }

    auto final_result = std::make_shared<std::experimental::promise<FinalResult>>();
    struct DoneCheck
    {
        std::shared_ptr<std::experimental::promise<FinalResult>> final_result;

        DoneCheck(std::shared_ptr<std::experimental::promise<FinalResult>> final_result_)
            : final_result(std::move(final_result_)) {}

        void operator()(std::experimental::future<std::experimental::when_any_result<
                            std::vector<std::experimental::future<MyData *>>>>
                            results_param)
        {
            auto results = results_param.get();
            MyData *const ready_result = results.futures[results.index].get();

            if (ready_result) final_result->set_value(process_found_value(*ready_result));
            else
            {
                results.futures.erase(results.futures.begin() + results.index);
                if (!results.futures.empty())
                {
                    std::experimental::when_any(results.futures.begin(), results.futures.end())
                        .then(std::move(*this));
                }
                else
                {
                    final_result->set_exception(
                        std::make_exception_ptr(std::runtime_error("Not found")));
                }
            }
        }
    };

    std::experimental::when_any(results.begin(), results.end())
        .then(DoneCheck(final_result));
    return final_result->get_future();
}
```
Giải thích:
- Dòng 10+: Khởi tạo một số `num_tasks` các tác vụ bất đồng bộ, mỗi tác vụ xử lý một đoạn dữ liệu độc lập.
- Dòng 13~23: Mỗi tác vụ tìm kiếm giá trị thỏa mãn tiêu chí trong phạm vi của nó. Nếu tìm thấy, nó cập nhật `done_flag` và trả về kết quả.
- Dòng 61+: Gọi `when_any()` để chờ bất kỳ future nào hoàn thành. Khi có một future hoàn thành, `DoneCheck()` được gọi.
- Dòng 41: Lấy giá trị từ future hoàn thành.
- Dòng 43: Nếu giá trị phù hợp, xử lý và đặt kết quả cuối cùng.
- Dòng 46: Nếu không có giá trị, loại bỏ future này khỏi tập hợp.
- Dòng 50: Gọi lại `when_any()` cho tập hợp còn lại.
- Dòng 55: Nếu không còn future nào, ném ngoại lệ "Not found".
- Dòng 63: Trả về future của kết quả cuối cùng.

### 4.7. Latch và barrier

Latch (cái chốt): Là công cụ đồng bộ dùng để chờ một số sự kiện xảy ra. Nó có một bộ đếm, và khi bộ đếm giảm về 0, latch được "mở". Sau khi mở, latch giữ nguyên trạng thái sẵn sàng cho đến khi bị hủy.
> Ví dụ: Bạn chờ đủ 5 người đến trước khi bắt đầu buổi họp. Khi đủ 5 người (bộ đếm = 0), bạn bắt đầu họp.

Barrier (cái rào chắn): Là công cụ đồng bộ dùng để đảm bảo tất cả các thread đến "điểm hẹn" trước khi cùng tiến hành công việc tiếp theo. Khi tất cả đã đến, barrier được "mở", và barrier có thể được dùng lại cho chu kỳ đồng bộ tiếp theo.
> Ví dụ: Mọi người đi bộ đường dài, và mỗi người có thể đi nhanh hoặc chậm. Nhưng tại mỗi điểm hẹn, mọi người phải đợi nhau. Sau khi cả nhóm đã đến, tất cả mới cùng nhau tiếp tục sang chặng tiếp theo.

So sánh:
- Latch:
    + Đơn giản hơn, chỉ cần chờ đủ điều kiện (bộ đếm về 0).
    + Thường dùng để khởi động một lần, không tái sử dụng.
- Barrier:
    + Đồng bộ phức tạp hơn, yêu cầu tất cả các thread phải đồng bộ trong từng chu kỳ.
    + Có thể dùng lại trong nhiều giai đoạn hoặc vòng lặp đồng bộ.

### 4.8. Giới thiệu std::experimental::latch

Header `<experimental/latch>` cung cấp `std::experimental::latch`, như đã giới thiệu ở phần trước, latch hoạt động dựa trên bộ đếm, và khi bộ đếm giảm về 0, latch chuyển sang trạng thái "ready". Chức năng chính của `std::experimental::latch`:
- `count_down()`: Giảm giá trị bộ đếm.
- `wait()`: Chờ latch ready (bộ đếm = 0).
- `is_ready()`: Kiểm tra latch đã ready hay chưa.
- `count_down_and_wait()`: Vừa giảm bộ đếm vừa chờ cho latch ready.

Ví dụ cơ bản:
```cpp
void foo()
{
    unsigned const thread_count = ...;
    latch done(thread_count);
    my_data data[thread_count];
    std::vector<std::future<void>> threads;

    for (unsigned i = 0; i < thread_count; ++i)
        threads.push_back(std::async(std::launch::async, [&, i] {
            data[i] = make_data(i);
            done.count_down();
            do_more_stuff();
        }));

    done.wait();
    process_data(data, thread_count);
}
```
Giải thích:
- Dòng 4: Một latch `done` được khởi tạo với giá trị ban đầu của counter (bộ đếm) là `thread_count`.
- Dòng 9: Tạo thread với `std::async`, chú ý nên **capture by value** với `i`, vì nó là biến đếm vòng lặp.
- Dòng 11: Mỗi thread, sau khi xử lý xong phần dữ liệu của nó, thì gọi `count_down()` trên latch để giảm giá trị bộ đếm, báo hiệu rằng sự kiện đã hoàn thành.
- Dòng 15: Thread chính gọi `done.wait()`để chờ tất cả các thread khác hoàn tất `count_down()`.

Những điểm đáng chú ý:
- Trường hợp không cần latch: Nếu các thread không có công việc bổ sung sau khi xử lý dữ liệu (dòng 12 `do_more_stuff()`), thì bạn không cần latch. Thay vào đó, có thể chỉ cần chờ các `std::future` từ `std::async`.
- Không tái sử dụng latch: `std::experimental::latch` chỉ phù hợp với các trường hợp đồng bộ một lần duy nhất.

### 4.9. Giới thiệu std::experimental::barrier

Header `<experimental/barrier>` có hai loại barrier:
- `std::experimental::barrier`: Loại cơ bản, nhẹ nhàng, tối ưu cho các trường hợp đơn giản.
- `std::experimental::flex_barrier`: Linh hoạt hơn, hỗ trợ thêm tính năng nhưng thêm chi phí xử lý.

Barrier được thiết kế để đồng bộ các thread trong các chu kỳ xử lý dữ liệu. Khi tất cả các thread đã hoàn tất công việc của mình và đến "điểm hẹn", barrier giải phóng tất cả các thread và sau đó tự reset để sử dụng lại cho chu kỳ tiếp theo.

Cách hoạt động:
- Khi tạo barrier, bạn chỉ định số lượng thread tham gia đồng bộ.
- Các thread gọi `arrive_and_wait()` để báo rằng chúng đã hoàn thành công việc.
- Khi thread cuối cùng trong nhóm đến barrier, tất cả thread được giải phóng để tiếp tục xử lý.
- Nếu một thread muốn rời nhóm, nó gọi `arrive_and_drop()`, và số thread cần đồng bộ ở chu kỳ tiếp theo giảm đi.

Ví dụ cách sử dụng barrier:
```cpp
result_chunk process(data_chunk);
std::vector<data_chunk> divide_into_chunks(data_block data, unsigned num_threads);

void process_data(data_source &source, data_sink &sink)
{
    unsigned const concurrency = std::thread::hardware_concurrency();
    unsigned const num_threads = (concurrency > 0) ? concurrency : 2;
    std::experimental::barrier sync(num_threads);
    std::vector<joining_thread> threads(num_threads);
    std::vector<data_chunk> chunks;
    result_block result;

    for (unsigned i = 0; i < num_threads; ++i)
    {
        threads[i] = joining_thread([&, i]
            {
                while (!source.done())
                {
                    if (0 == i)
                    {
                        data_block current_block = source.get_next_data_block();
                        chunks = divide_into_chunks(current_block, num_threads);
                    }
                    sync.arrive_and_wait();
                    result.set_chunk(i, num_threads, process(chunks[i]));
                    sync.arrive_and_wait();
                    if (0 == i)
                    {
                        sink.write_data(std::move(result));
                    }
                }
            });
    }
}
```
Giải thích:
- Dòng 8: Một barrier `sync` được khởi tạo với số lượng thread cần đồng bộ `num_threads`.
- Dòng 19~22: Thread `i = 0` chia dữ liệu thành các phần (chunks) để phân cho các thread khác xử lý.
- Dòng 24: Tất cả các thread `arrive_and_wait()` chờ thread `i = 0` hoàn thành công việc chia chunks.
- Dòng 25: Các thread thực hiện `process(chunks[i])` song song và cập nhật result.
- Dòng 26: Tất cả lại `arrive_and_wait()` đồng bộ lần nữa trước khi thread `i = 0` viết kết quả cuối cùng vào sink.
- Dòng 17: Vòng lặp tiếp tục cho đến khi `source.done()`.

### 4.10. Giới thiệu std::experimental::flex_barrier

`std::experimental::flex_barrier` mở rộng từ `std::experimental::barrier` với một điểm khác biệt quan trọng: Nó hỗ trợ một completion function (hàm hoàn tất), được chỉ định thông qua constructor. Hàm này sẽ được chạy bởi đúng một thread khi tất cả các thread đã đến barrier. Completion function không chỉ cho phép thực thi một đoạn mã tuần tự, mà còn cho phép thay đổi số lượng thread cần đồng bộ trong chu kỳ kế tiếp.
> Lưu ý: Cần đảm bảo số lượng thread tham gia ở chu kỳ tiếp theo được quản lý đúng cách, nếu không sẽ dẫn đến lỗi đồng bộ.

Ví dụ sử dụng flex_barrier:
```cpp
void process_data(data_source &source, data_sink &sink)
{
    unsigned const concurrency = std::thread::hardware_concurrency();
    unsigned const num_threads = (concurrency > 0) ? concurrency : 2;
    std::vector<data_chunk> chunks;

    auto split_source = [&] {
        if (!source.done())
        {
            data_block current_block = source.get_next_data_block();
            chunks = divide_into_chunks(current_block, num_threads);
        }
    };
    split_source();
    result_block result;

    std::experimental::flex_barrier sync(num_threads, [&] {
        sink.write_data(std::move(result));
        split_source();
        return -1;
    });

    std::vector<joining_thread> threads(num_threads);
    for (unsigned i = 0; i < num_threads; ++i)
    {
        threads[i] = joining_thread([&, i] {
            while (!source.done())
            {
                result.set_chunk(i, num_threads, process(chunks[i]));
                sync.arrive_and_wait();
            }
        });
    }
}
```
Giải thích:
- Dòng 7~14: Lambda `split_source` chia dữ liệu thành các chunks nhỏ và được gọi để thực hiện ban đầu nhằm chuẩn bị data cho for loop.
- Dòng 17~20: Sử dụng `flex_barrier` và cung cấp completion function (lambda) thực hiện `sink.write_data()`, rồi lại gọi `split_source` chuẩn bị data cho chu kỳ kế tiếp. Completion function có `return -1` nghĩa là giữ nguyên số lượng thread đồng bộ, có thể `return <number>` với number là 0 hoặc số dương để quyết định số thread ở chu kỳ tiếp theo.

Điểm đáng chú ý: Vòng lặp chính (dòng 27~31) chỉ chứa phần xử lý song song, các đoạn mã tuần tự được chuyển vào completion function, giúp giảm phức tạp và chỉ cần một điểm `arrive_and_wait()` dòng 30.

## 5. Tài liệu tham khảo

- [1] Anthony Williams, "4. Synchronizing concurrent operations" in *C++ Concurrency in Action*, 2nd Edition, 2019.

[//]: # (----------SCOPE OF DECLARATION OF LIST OF IMAGES USED IN POST----------)
[img_1]: /assets/img/2024-11-CXX-concurrency-chap-4/01_concept_of_duration_and_time_point.png "Khái niệm về duration, time point, và epoch"
[img_1d]: /assets/img/2024-11-CXX-concurrency-chap-4/01d_concept_of_duration_and_time_point.png "Khái niệm về duration, time point, và epoch"
[img_2]: /assets/img/2024-11-CXX-concurrency-chap-4/02_demo_quick_sort.png "Ví dụ về quick-sort"
[img_2d]: /assets/img/2024-11-CXX-concurrency-chap-4/02d_demo_quick_sort.png "Ví dụ về quick-sort"
[img_3]: /assets/img/2024-11-CXX-concurrency-chap-4/03_ATM_simple_state_machine.png "State machine đơn giản của hệ thống ATM"
[img_3d]: /assets/img/2024-11-CXX-concurrency-chap-4/03d_ATM_simple_state_machine.png "State machine đơn giản của hệ thống ATM"
