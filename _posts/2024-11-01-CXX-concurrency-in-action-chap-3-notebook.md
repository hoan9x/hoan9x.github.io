---
title: "Chương 3: Sharing data between threads"
description: Ghi chép trong quá trình đọc cuốn sách C++ Concurrency in Action của Anthony Williams
author: hoan9x
date: 2024-11-01 10:00:00 +0700
categories: [CXX, Multi-Threading]
mermaid: true
---

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

### 2.2. Cấu trúc mã để bảo vệ dữ liệu được chia sẻ
{: #refer-22-cau-truc-ma-de-bao-ve-du-lieu-chia-duoc-chia-se }

Để bảo vệ dữ liệu được chia sẻ một cách hiệu quả, cần đảm bảo rằng tất cả các đoạn mã truy cập dữ liệu đều được bảo vệ bởi mutex. Tránh pass by pointer hoặc reference đến dữ liệu được bảo vệ ra khỏi phạm vi khóa.

Ví dụ trường hợp vô tình truyền ra một tham chiếu đến dữ liệu được bảo vệ:
```cpp
class some_data
{
    int a;
    std::string b;
public:
    void do_something();
};

class data_wrapper
{
private:
    some_data data;
    std::mutex m;
public:
    template <typename Function>
    void process_data(Function func)
    {
        std::lock_guard<std::mutex> l(m);
        func(data);
    }
};

some_data *unprotected;
void malicious_function(some_data &protected_data)
{
    unprotected = &protected_data;
}
data_wrapper x;
void foo()
{
    x.process_data(malicious_function);
    unprotected->do_something();
}
```

- Dòng 9: `class data_wrapper` đang cố gắng bảo vệ `some_data data;`, và class này có interface `process_data()` với parameter là hàm bất kỳ.
- Dòng 31: Thực hiện gọi `process_data()` của `data_wrapper` và đưa vào hàm `malicious_function()`, và hàm này lại lấy reference đến dữ liệu muốn được bảo vệ trong `data_wrapper`.

Như vậy, việc bảo vệ dữ liệu không đơn giản là chỉ thêm đối tượng `std::lock_guard` vào các interfaces, nếu xuất hiện một pointer hoặc reference, tất cả sự bảo vệ đều là vô ích.

### 2.3. Phát hiện race conditions trong interface

Xem xét các interface của một cấu trúc dữ liệu `stack` sau:
```cpp
template <typename T, typename Container = std::deque<T>>
class stack
{
public:
    explicit stack(const Container &);
    explicit stack(Container && = Container());
    template <class Alloc> explicit stack(const Alloc &);
    template <class Alloc> stack(const Container &, const Alloc &);
    template <class Alloc> stack(Container &&, const Alloc &);
    template <class Alloc> stack(stack &&, const Alloc &);

    bool empty() const;
    size_t size() const;
    T &top();
    T const &top() const;
    void push(T const &);
    void push(T &&);
    void pop();
    void swap(stack &&);
    template <class... Args> void emplace(Args &&...args);
};
```

Để bảo vệ cấu trúc dữ liệu `stack` trên khỏi race condition, bạn phải chỉnh sửa interface `top()` để nó return copy object thay vì reference (để tuân thủ vấn đề đã nói ở [mục 2.2](#refer-22-cau-truc-ma-de-bao-ve-du-lieu-chia-duoc-chia-se)) và bảo vệ dữ liệu nội bộ bằng mutex, ví dụ:
```cpp
template <typename T, typename Container = std::deque<T>>
class stack
{
public:
    ...
    bool empty() const
    {
        std::lock_guard<std::mutex> lock(mtx);
        return data.is_empty();
    }
    size_t size() const
    {
        std::lock_guard<std::mutex> lock(mtx);
        return data.check_size();
    }
    T top() const
    {
        std::lock_guard<std::mutex> lock(mtx);
        return data.top_value();
    }
    void push(T const &value)
    {
        std::lock_guard<std::mutex> lock(mtx);
        data.add_item(value);
    }
    void pop()
    {
        std::lock_guard<std::mutex> lock(mtx);
        data.remove_item();
    }
    ...
private:
    T data;
    std::mutex mtx;
};
```

Nhưng chỉ với các chỉnh sửa trên, thì interface của `stack` này vẫn có thể gặp phải race condition. Vấn đề ở đây là kết quả trả về của hai hàm `empty()` và `size()` không đáng tin cậy. Mặc dù chúng có thể đúng tại thời điểm gọi hàm, nhưng các thread khác có thể truy cập `stack` để `push()` hoặc `pop()` làm thay đổi thông tin `empty()` và `size()` trước khi thread này sử dụng thông tin trả về từ `empty()` và `size()`.

Ví dụ vấn đề `empty()` và `size()` không đáng tin cậy:
```cpp
stack<int> shared_stack;
if (!shared_stack.empty())
{
    const int value = shared_stack.top();
    shared_stack.pop();
    do_something(value);
}
```

Xét timeline (dòng thời gian) thứ nhất có thể xảy ra với mã nguồn trên:

| Timeline | Thread A                              | Thread B                              |
| -------- | ------------------------------------- | ------------------------------------- |
| 1        | if(!shared_stack.empty())             |                                       |
| 2        |                                       | const int value = shared_stack.top(); |
| 3        | const int value = shared_stack.top(); |                                       |

> - Ở timeline 1, ta có Thread A sẽ kiểm tra `shared_stack` nếu không `empty()` thì Thread A sẽ lấy giá trị trong stack bằng `top()`.
> - Nhưng sau khi Thread A đã kiểm tra `empty()`, đến timeline 2, có thể xảy ra trường hợp Thread B đã lấy giá trị trong stack bằng `top()`.
> - Như vậy, thông tin mà Thread A xác nhận `empty()` ở timeline 1 đã bị sai lệch, và nếu stack đã thật sự `empty()` bởi vì Thread B vừa lấy giá trị cuối cùng, thì việc Thread A lấy stack bằng `top()` ở timeline 3 sẽ có vấn đề.

Xét timeline thứ hai có thể xảy ra:

| Timeline | Thread A                              | Thread B                              |
| -------- | ------------------------------------- | ------------------------------------- |
| 1        | if (!shared_stack.empty())            |                                       |
| 2        |                                       | if (!shared_stack.empty())            |
| 3        | const int value = shared_stack.top(); |                                       |
| 4        |                                       | const int value = shared_stack.top(); |
| 5        | shared_stack.pop();                   |                                       |
| 6        | do_something(value);                  | shared_stack.pop();                   |
| 7        |                                       | do_something(value);                  |

> - Ở timeline 1 và 2, hai Thread A và B lần lượt kiểm tra `shared_stack` có bị `empty()` hay không.
> - Nếu `shared_stack` không bị `empty()`, thì ở timeline 3 và 4, có thể hai thread sẽ lần lượt lấy cùng một giá trị `top()`.
> - Nhưng đến timeline 5 và 6, Thread A và B lại thực hiện xóa tận hai giá trị bằng `pop()`.
> - Như vậy, ở trường hợp này có tận hai giá trị trong `shared_stack` bị xóa, trong khi chỉ có một giá trị nhưng lại được xử lý tận hai lần ở timeline 6 và 7 với `do_something(value)`.

- Giải pháp tránh timeline thứ nhất xảy ra: Có thể cho `top()` thực hiện kiểm tra `empty()` nội bộ trước khi trả về dữ liệu, và nếu stack bị rỗng thì có thể ném ngoại lệ, mã ví dụ:
```cpp
template <typename T, typename Container = std::deque<T>>
class stack
{
public:
    ...
    T top() const
    {
        std::lock_guard<std::mutex> lock(mtx);
        if (data.is_empty()) throw runtime_error("stack is empty");
        return data.top_value();        
    }
    ...
private:
    T data;
    std::mutex mtx;
};
```
Cách này có thể giải quyết vấn đề, nhưng nó sẽ làm cho việc lập trình trở nên cồng kềnh, vì mỗi lần muốn gọi `top()` thì phải bắt ngoại lệ.

- Giải pháp tránh timeline thứ hai xảy ra: Gộp `top()` và `pop()` lại thành một, mã ví dụ:
```cpp
template <typename T, typename Container = std::deque<T>>
class stack
{
public:
    ...
    T top() const
    {
        std::lock_guard<std::mutex> lock(mtx);
        if (data.is_empty()) throw runtime_error("stack is empty");
        T retValue = data.top_value();
        data.remove_item();
        return retValue;
    }
    ...
private:
    T data;
    std::mutex mtx;
};
```
Như vậy, người dùng `class stack` chỉ cần sử dụng mỗi `top()` để lấy giá trị, và nó cũng thực hiện xóa giá trị trong stack rồi, nên không phải xóa giá trị bằng `pop()` sau đó nữa. Tuy nhiên, giải pháp này dễ gây lỗi khi sử dụng `class stack` cho các kiểu dữ liệu phức tạp như `vector`. Ví dụ, nếu dùng `stack<vector<int>>`, việc return copy object của `top()` có thể yêu cầu nhiều bộ nhớ, và nếu không đủ bộ nhớ, một ngoại lệ `std::bad_alloc` sẽ được ném ra. Nếu lỗi này xảy ra sau khi phần tử đã bị xóa ra khỏi stack nhưng chưa trả về thành công, dữ liệu đó sẽ bị mất vĩnh viễn. Để hạn chế lỗi này, thư viện chuẩn C++ mới thiết kế interface `top()` và `pop()` thành hai lệnh riêng biệt như vậy, nó cho phép dữ liệu vẫn giữ trên stack nếu không thể copy object thành công.

Tóm lại, việc thiết kế interface để tránh race condition là khá khó khăn. Nhưng cũng không phải là không thể, sau đây là các giải pháp để khắc phục thay thế:
- OPTION 1: PASS IN A REFERENCE (truyền tham chiếu).
Truyền tham chiếu dữ liệu mà bạn muốn nhận giá trị từ `pop()`. Cách này chỉ có nhược điểm là phải khởi tạo instance của dữ liệu trước khi gọi `pop()` (giống như cấp phát bộ nhớ trước rồi mới sử dụng nó để nhận dữ liệu).
```cpp
std::vector<int> result;
some_stack.pop(result);
```
- OPTION 2: REQUIRE A NO-THROW COPY CONSTRUCTOR OR MOVE CONSTRUCTOR (cần copy constructor không ném ngoại lệ `std::bad_alloc` hoặc move constructor).
- OPTION 3: RETURN A POINTER TO THE POPPED ITEM (trả về kiểu con trỏ thay vì copy object).
Ưu điểm ở đây là các con trỏ có thể được sao chép tự do mà không ném ra ngoại lệ. Nhược điểm là việc trả về con trỏ yêu cầu phải quản lý bộ nhớ, và nếu đối tượng là các kiểu đơn giản như `int`, chi phí quản lý bộ nhớ có thể vượt quá chi phí trả về theo kiểu copy object. Lưu ý, thay vì trả về kiểu raw pointer thì hãy sử dụng smart pointer thay thế như `std::shared_ptr` để tránh rò rỉ bộ nhớ.
- OPTION 4: PROVIDE BOTH OPTION 1 AND EITHER OPTION 2 OR 3 (kết hợp giữa những giải pháp đã nói bên trên).
Dùng function overloading (nạp chồng hàm) để thiết kết các interface có thể thỏa mãn hết các giải pháp đã nói bên trên.
```cpp
#include <exception>    // for std::exception
#include <memory>       // for std::shared_ptr
#include <mutex>
#include <stack>
struct empty_stack: std::exception
{
    const char *what() const throw();
};
template <typename T>
class threadsafe_stack
{
private:
    std::stack<T> data;
    mutable std::mutex mtx;
public:
    threadsafe_stack() {}
    threadsafe_stack(const threadsafe_stack &other)
    {
        std::lock_guard<std::mutex> lock(other.mtx);
        data = other.data;
    }
    threadsafe_stack &operator=(const threadsafe_stack &) = delete;
    void push(T new_value)
    {
        std::lock_guard<std::mutex> lock(mtx);
        data.push(std::move(new_value));
    }
    std::shared_ptr<T> pop()
    {
        std::lock_guard<std::mutex> lock(mtx);
        if (data.empty())
            throw empty_stack();
        std::shared_ptr<T> const res(std::make_shared<T>(data.top()));
        data.pop();
        return res;
    }
    void pop(T &value)
    {
        std::lock_guard<std::mutex> lock(mtx);
        if (data.empty())
            throw empty_stack();
        value = data.top();
        data.pop();
    }
    bool empty() const
    {
        std::lock_guard<std::mutex> lock(mtx);
        return data.empty();
    }
};
```

### 2.4. Vấn đề về deadlock và biện pháp giải quyết

Câu chuyện bắt đầu với hai đứa trẻ và một món đồ chơi cần hai phần để chơi (ví dụ: trống và dùi trống - drum and drumstick). Nếu một đứa trẻ có cả hai phần, nó có thể chơi thoải mái với chúng, nhưng nếu một đứa khác muốn chơi, thì phải chờ. Sau đó, nếu cả hai đứa trẻ cùng đi tìm đồ chơi và mỗi đứa chỉ tìm được một phần, chúng sẽ không thể chơi được vì mỗi đứa đều muốn tranh phần còn lại.

Trong lập trình, câu chuyện trên giống như hai threads cần hai mutexes để thực hiện một tác vụ, nhưng mỗi thread lại chỉ giữ một mutex và chờ mutex còn lại từ luồng kia. Kết quả là cả hai threads bị treo vĩnh viễn, đây chính là vấn đề deadlock.
```cpp
int main()
{
    std::mutex mtxDrum;
    std::mutex mtxDrumstick;
    std::thread t1([&mtxDrum, &mtxDrumstick] {
        std::cout << "Thread 1: Acquiring drum\n";
        mtxDrum.lock();
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
        std::cout << "Thread 1: Acquiring drumstick\n";
        mtxDrumstick.lock(); 
    });
    std::thread t2([&mtxDrum, &mtxDrumstick] {
        std::cout << "Thread 2: Acquiring drumstick\n";
        mtxDrumstick.lock();
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
        std::cout << "Thread 2: Acquiring drum\n";
        mtxDrum.lock();
    });
    t1.join();
    t2.join();
}
```

Để tránh deadlock thì tốt nhất là luôn khóa hai mutex theo cùng một thứ tự trước sau, ví dụ:
```cpp
std::thread t1([&mtxDrum, &mtxDrumstick] {
    std::cout << "Thread 1: Acquiring drumstick\n";
    mtxDrumstick.lock(); 
    std::cout << "Thread 1: Acquiring drum\n";
    mtxDrum.lock();
    std::cout << "Thread 1: Play the drums\n";
    std::this_thread::sleep_for(std::chrono::milliseconds(10));
    mtxDrum.unlock();
    mtxDrumstick.unlock();
});
std::thread t2([&mtxDrum, &mtxDrumstick] {
    std::cout << "Thread 2: Acquiring drumstick\n";
    mtxDrumstick.lock();
    std::cout << "Thread 2: Acquiring drum\n";
    mtxDrum.lock();
    std::cout << "Thread 2: Play the drums\n";
    std::this_thread::sleep_for(std::chrono::milliseconds(10));
    mtxDrum.unlock();
    mtxDrumstick.unlock();
});
```

Nhưng sẽ có trường hợp không thể biết khóa mutex có thể được khóa theo thứ tự không. Ví dụ, hàm `swap()` thực hiện hoán đổi hai instances của cùng một class:
```cpp
class some_big_object;
void swap(some_big_object &lhs, some_big_object &rhs);
class X
{
private:
    some_big_object some_detail;
    std::mutex mtx;
public:
    X(some_big_object const &sd) : some_detail(sd) {}
    friend void swap(X &lhs, X &rhs)
    {
        if (&lhs == &rhs)
            return;
        lhs.mtx.lock();
        rhs.mtx.lock();
        swap(lhs.some_detail, rhs.some_detail);
        rhs.mtx.unlock();
        lhs.mtx.unlock();
    }
};
```
{: #refer-swap-func }
Hàm `swap()` trên có thể gây ra vấn đề deadlock khi các threads thực hiện gọi `swap()` và truyền đối số theo thứ tự ngược nhau (vì tham số là cùng một loại).

Để tránh tình huống deadlock như vậy, thư viện chuẩn C++ cung cấp một giải pháp gọi là `std::lock`. Hàm `std::lock` cho phép bạn khóa nhiều mutexes cùng một lúc mà không lo ngại đến thứ tự khóa. Sửa ví dụ hàm `swap()` trên sử dụng `std::lock`:
```cpp
void swap(X &lhs, X &rhs)
{
    if (&lhs == &rhs)
        return;
    std::lock(lhs.mtx, rhs.mtx);
    std::lock_guard<std::mutex> lock_a(lhs.mtx, std::adopt_lock);
    std::lock_guard<std::mutex> lock_b(rhs.mtx, std::adopt_lock);
    swap(lhs.some_detail, rhs.some_detail);
}
```
Tham số `std::adopt_lock` để chỉ cho `std::lock_guard` biết rằng các mutex đã bị khóa bởi `std::lock`.

Từ C++17 trở đi, có thể sử dụng `std::scoped_lock` để thay thế `std::lock` và `std::lock_guard`:
```cpp
void swap(X &lhs, X &rhs)
{
    if (&lhs == &rhs)
        return;
    // since C++17
    std::scoped_lock guard(lhs.mtx,rhs.mtx);
    swap(lhs.some_detail, rhs.some_detail);
}
```

### 2.5. Các quy tắc chung để phòng tránh deadlock

Deadlock không chỉ xảy ra với khóa mutex mà còn có thể xảy ra khi các thread gọi `join()` lẫn nhau, nó sẽ làm cho chương trình bị treo. Nói chung, để tránh deadlock, quy tắc cơ bản là không đợi một thread nếu có thể thread đó đang đợi bạn.

Như vậy, có thể tổng hợp một số các quy tắc chung để phòng tránh deadlock khi lập trình:
- Tránh khóa lồng nhau: Không nên lock thêm nữa nếu bạn đã giữ một lock. Nếu cần lock nhiều, hãy dùng `std::lock`.
- Cẩn thận khi phát triển, sử dụng các thư viện có khóa mutex: Ví dụ như hàm [`swap()`](#refer-swap-func) đã giải thích ở trên. Khi phát triển các APIs, cần phải cẩn thận với các thao tác người dùng có thể thực hiện với APIs đó.
- Thực hiện locks theo thứ tự cố định: Khi cần nhiều locks và không thể dùng `std::lock`, hãy đảm bảo rằng mọi thread lấy locks theo cùng một thứ tự.
- Sử dụng hệ thống lock hierarchy (khóa phân cấp): Hệ thống lock hierarchy giúp các mutex được khóa theo thứ tự đúng trong suốt quá trình thực thi, tránh được deadlock. Ý tưởng là mỗi mutex được gán một level, và các thread không thể khóa mutex có level thấp hơn khi đã khóa mutex có level cao hơn. Triển khai mã `hierarchical_mutex` ví dụ:
```cpp
class hierarchical_mutex
{
    std::mutex internal_mutex;
    unsigned long const hierarchy_value;
    unsigned long previous_hierarchy_value;
    static thread_local unsigned long this_thread_hierarchy_value;
    void check_for_hierarchy_violation()
    {
        if (this_thread_hierarchy_value <= hierarchy_value)
        {
            throw std::logic_error("mutex hierarchy violated");
        }
    }
    void update_hierarchy_value()
    {
        previous_hierarchy_value = this_thread_hierarchy_value;
        this_thread_hierarchy_value = hierarchy_value;
    }
public:
    explicit hierarchical_mutex(unsigned long value) : hierarchy_value(value),
                                                       previous_hierarchy_value(0)
    {
    }
    void lock()
    {
        check_for_hierarchy_violation();
        internal_mutex.lock();
        update_hierarchy_value();
    }
    void unlock()
    {
        if (this_thread_hierarchy_value != hierarchy_value)
            throw std::logic_error("mutex hierarchy violated");
        this_thread_hierarchy_value = previous_hierarchy_value;
        internal_mutex.unlock();
    }
    bool try_lock()
    {
        check_for_hierarchy_violation();
        if (!internal_mutex.try_lock())
            return false;
        update_hierarchy_value();
        return true;
    }
};
thread_local unsigned long hierarchical_mutex::this_thread_hierarchy_value(ULONG_MAX);
```
Mã triển khai `hierarchical_mutex` trên sử dụng biến `thread_local` để lưu trữ level của từng thread riêng biệt, giúp kiểm tra sự phân cấp ở mỗi thread mà không bị ảnh hưởng lẫn nhau. Giá trị `this_thread_hierarchy_value` cũng được khởi tạo với giá trị `ULONG_MAX` (giá trị tối đa), do đó ban đầu bất kỳ mutex nào cũng có thể bị khóa. Lưu ý, triển khai `hierarchical_mutex` trên không thể khóa nhiều mutex ở cùng một level, điều này có thể không thực tế trong một số trường hợp.

### 2.6. Khóa mutex linh hoạt hơn với std::unique_lock

Khóa mutex bằng `std::unique_lock` thì linh hoạt hơn `std::lock_guard`. Bạn có thể truyền đối số `std::defer_lock` cho `std::unique_lock` để giữ mutex không bị khóa khi khởi tạo instance, và sau đó khóa mutex sau bằng cách gọi `lock()` hoặc dùng `std::lock()`.

```cpp
void swap(X &lhs, X &rhs)
{
    if (&lhs == &rhs)
        return;
    // std::defer_lock leaves mutexes unlocked
    std::unique_lock<std::mutex> lock_a(lhs.mtx, std::defer_lock);
    std::unique_lock<std::mutex> lock_b(rhs.mtx, std::defer_lock);
    std::lock(lock_a, lock_b); // Mutexes are locked here
    swap(lhs.some_detail, rhs.some_detail);
}
```
Trong ví dụ trên, các đối tượng `std::unique_lock` có thể được truyền vào `std::lock()`, vì `std::unique_lock` cung cấp các phương thức `lock()`, `try_lock()`, `unlock()` để kiểm soát khóa mutex, và sử dụng cờ để theo dõi quyền sở hữu mutex (dùng `owns_lock()` để kiểm tra cờ này).

Đối tượng `std::unique_lock` có nhược điểm là dung lượng instance lớn hơn và tốn chi phí tính toán nhiều hơn `std::lock_guard` do phải lưu trữ và cập nhật cờ sở hữu mutex.
Nếu không cần tính năng linh hoạt này, bạn nên sử dụng `std::lock_guard` vì đơn giản và hiệu quả hơn.

### 2.7. Chuyển quyền sở hữu mutex giữa các phạm vi

`std::unique_lock` cho phép chuyển nhượng quyền sở hữu của khóa mutex giữa các đối tượng. Điều này có nghĩa là bạn có thể chuyển giao mutex từ đối tượng này sang đối tượng khác, thay vì giữ nó cố định trong suốt vòng đời của đối tượng.
- Nếu đối tượng `std::unique_lock` là rvalue (ví dụ: một đối tượng tạm thời), quyền sở hữu mutex sẽ được chuyển tự động khi bạn trả về đối tượng từ một hàm.
- Nếu đối tượng là lvalue (biến đã tồn tại), chuyển nhượng bằng `std::move()`.

```cpp
std::unique_lock<std::mutex> get_lock()
{
    extern std::mutex some_mutex;
    std::unique_lock<std::mutex> lk(some_mutex);
    prepare_data();
    return lk;
}
void process_data()
{
    std::unique_lock<std::mutex> lk(get_lock());
    do_something();
}
```
Trong ví dụ trên, hàm `get_lock()` khóa mutex và trả lại đối tượng `std::unique_lock` cho hàm `process_data()`. Khi đó, quyền sở hữu khóa mutex tự động được chuyển từ `get_lock()` sang `process_data()`, mà không cần sử dụng `std::move()`.

### 2.8. Khóa mutex với granularity tối ưu

Lock granularity (độ chi tiết của khóa) là một khái niệm đề cập đến mức độ dữ liệu mà một khóa bảo vệ:
- Fine-grained lock (khóa một cách chi tiết, khóa mịn) là bảo vệ một phần nhỏ của dữ liệu, chẳng hạn như một biến hay một item trong mảng.
- Coarse-grained lock (khóa thô) là bảo vệ phần lớn dữ liệu, chẳng hạn như toàn bộ cấu trúc dữ liệu.

Chọn lock granularity phù hợp rất quan trọng để bảo vệ dữ liệu, đảm bảo khóa chỉ được giữ trong thời gian cần thiết.

Chúng ta đều từng cảm thấy khó chịu khi đứng chờ ở quầy thanh toán trong siêu thị, chỉ để thấy khách hàng trước quên món đồ nào đó và phải quay lại tìm, làm cho mọi người phải đợi lâu hơn.

Tương tự, trong lập trình, nếu nhiều threads đang chờ cùng một tài nguyên mà có một thread giữ khóa lâu hơn mức cần thiết, thì thời gian chờ sẽ tăng lên, làm giảm hiệu suất.

Ví dụ dưới đây sử dụng `std::unique_lock`, vì nó cho phép `unlock()` khi không cần truy cập dữ liệu và `lock()` lại khi cần truy cập lại:
```cpp
void get_and_process_data()
{
    std::unique_lock<std::mutex> my_lock(the_mutex);
    some_class data_to_process = get_next_data_chunk();
    my_lock.unlock();
    result_type result = process(data_to_process);
    my_lock.lock();
    write_result(data_to_process, result);
}
```
Ở đây, không cần giữ khóa trong khi gọi `process()`. Điều này giúp giảm thời gian giữ khóa, tăng hiệu suất chương trình.

Quy tắc để chọn lock granularity phù hợp là chỉ giữ khóa trong khoảng thời gian tối thiểu cần thiết. Không nên giữ khóa với các thao tác tốn thời gian như đọc/ghi tệp, trừ khi thực sự cần thiết.

Tuy nhiên, cần phải cẩn thận chọn lock granularity để không làm thay đổi ngữ nghĩa chương trình và dẫn đến các vấn đề race condition. Ví dụ:
```cpp
class Y
{
private:
    int some_detail;
    mutable std::mutex mtx;
    int get_detail() const
    {
        std::lock_guard<std::mutex> lock(mtx);
        return some_detail;
    }
public:
    Y(int sd) : some_detail(sd) {}
    friend bool operator==(Y const &lhs, Y const &rhs)
    {
        if (&lhs == &rhs)
            return true;
        int const lhs_value = lhs.get_detail();
        int const rhs_value = rhs.get_detail();
        return lhs_value == rhs_value;
    }
};
```
Trong ví dụ trên, hàm toán tử so sánh `operator==()` chỉ giữ khóa trong lúc lấy dữ liệu cần so sánh trong `get_detail()`, lý do là để giảm thời gian giữ khóa và tránh deadlock. Tuy nhiên, giá trị `some_detail` có thể sẽ thay đổi giữa các lần đọc `lhs.get_detail()` và `rhs.get_detail()`, gây ra race condition.

## 3. Giải pháp khác để bảo vệ dữ liệu được chia sẻ

Mặc dù mutex là cơ chế bảo vệ dữ liệu được chia sẻ phổ biến, nhưng không phải lúc nào cũng là lựa chọn tốt nhất. Trong một số trường hợp, dữ liệu chỉ cần được bảo vệ trong quá trình khởi tạo, và sau đó không cần bảo vệ nữa (ví dụ dữ liệu read-only). Trong những tình huống này, sử dụng mutex sau khi khởi tạo là dư thừa và ảnh hưởng đến hiệu suất. Vì vậy, chuẩn C++ cung cấp cơ chế riêng để bảo vệ dữ liệu chỉ trong quá trình khởi tạo.

### 3.1. Bảo vệ dữ liệu được chia sẻ trong lúc khởi tạo

Nếu bạn có một tài nguyên dùng chung mà chi phí xây dựng rất cao (ví dụ như cấp phát một lượng lớn bộ nhớ). Kỹ thuật lazy initialization (khởi tạo lười) sẽ thường được sử dụng:
```cpp
std::shared_ptr<some_resource> resource_ptr;
void foo()
{
    if(!resource_ptr)
    {
        resource_ptr.reset(new some_resource);
    }
    resource_ptr->do_something();
}
```
Lazy initialization nghĩa là khi muốn sử dụng tài nguyên thì tiến hành kiểm tra xem nó đã được khởi tạo chưa rồi mới khởi tạo nó.

Cần bảo vệ quá trình khởi tạo của tài nguyên để thread-safe như sau:
```cpp
std::shared_ptr<some_resource> resource_ptr;
std::mutex resource_mutex;
void foo()
{
    std::unique_lock<std::mutex> lk(resource_mutex);
    if(!resource_ptr)
    {
        resource_ptr.reset(new some_resource);
    }
    lk.unlock();
    resource_ptr->do_something();
}
```
Nhưng dùng mutex ở đây không tối ưu, nó khiến các luồng phải đợi nhau khi kiểm tra tài nguyên đã được khởi tạo hay chưa.

Một cách cải tiến là sử dụng pattern *double-checked locking*:
```cpp
void undefined_behaviour_with_double_checked_locking()
{
    if(!resource_ptr)
    {
        std::lock_guard<std::mutex> lk(resource_mutex);
        if(!resource_ptr)
        {
            resource_ptr.reset(new some_resource);
        }
    }
    resource_ptr->do_something();
}
```
Đáng tiếc, double-checked locking rất dễ gây ra race condition, vì hành động kiểm tra `if(!resource_ptr)` ngoài lock không được đồng bộ với việc khởi tạo bên trong lock, dẫn đến khả năng xảy ra undefined behaviour.

Một giải pháp tốt hơn là dùng `std::call_once` và `std::once_flag` trong C++11, nó giúp đảm bảo rằng tài nguyên chỉ được khởi tạo một lần duy nhất và an toàn trong môi trường đa luồng:
```cpp
std::shared_ptr<some_resource> resource_ptr;
std::once_flag resource_flag;
void init_resource()
{
    resource_ptr.reset(new some_resource);
}
void foo()
{
    std::call_once(resource_flag, init_resource);
    resource_ptr->do_something();
}
```

Cuối cùng, một tình huống tiềm ẩn race condition nữa là khi khởi tạo biến cục bộ `static`. Trong chuẩn C++ trước phiên bản C++11, việc khởi tạo biến `static` có thể dẫn đến race condition, vì nhiều luồng có thể cố gắng khởi tạo biến này cùng lúc. Tuy nhiên, từ C++11 trở đi, vấn đề này đã được giải quyết, và việc khởi tạo biến `static` được đảm bảo là an toàn trong môi trường multi-thread.
```cpp
class my_class;
my_class& get_my_class_instance()
{
    /* Thread-safe initialization static variables since C++11 */
    static my_class instance;
    return instance;
}
```

### 3.2. Bảo vệ dữ liệu mà nó ít khi sửa đổi

Giả sử bạn có một bộ đệm DNS lưu trữ các mục tên miền, dữ liệu này thường không cần thay đổi trong thời gian dài. Dù hành động cập nhật hiếm khi xảy ra, nhưng nếu bộ đệm được truy cập đồng thời từ nhiều threads, bạn vẫn cần phải bảo vệ nó khi nó cập nhật dữ liệu để tránh race condition.

Để tối ưu cho việc truy cập đồng thời, thay vì dùng `std::mutex` thông thường, bạn có thể sử dụng reader-writer mutex (như `std::shared_mutex`), cho phép nhiều threads đọc dữ liệu đồng thời trong khi vẫn đảm bảo việc truy cập độc quyền khi cập nhật dữ liệu.

C++17 cung cấp `std::shared_mutex` và `std::shared_timed_mutex`. C++14 chỉ có `std::shared_timed_mutex`, còn C++11 không hỗ trợ reader-writer mutex. Để sử dụng reader-writer mutex từ C++11 về trước, bạn có thể dùng thư viện Boost.

Dưới đây là ví dụ về bộ đệm DNS với `std::map`, sử dụng `std::shared_mutex` để bảo vệ dữ liệu:
```cpp
#include <map>
#include <string>
#include <mutex>
#include <shared_mutex>
class dns_entry;
class dns_cache
{
    std::map<std::string, dns_entry> entries;
    mutable std::shared_mutex entry_mutex;
public:
    dns_entry find_entry(std::string const &domain) const
    {
        std::shared_lock<std::shared_mutex> lk(entry_mutex);
        std::map<std::string, dns_entry>::const_iterator const it = entries.find(domain);
        return (it == entries.end()) ? dns_entry() : it->second;
    }

    void update_or_add_entry(std::string const &domain, dns_entry const &dns_details)
    {
        std::lock_guard<std::shared_mutex> lk(entry_mutex);
        entries[domain] = dns_details;
    }
};
```
Trong ví dụ trên, `find_entry()` sử dụng `std::shared_lock` để cho phép nhiều threads có thể đọc `std::map` đồng thời, trong khi `update_or_add_entry()` dùng `std::lock_guard` để đảm bảo hành động cập nhật `std::map` chỉ được thực hiện bởi một thread duy nhất.

### 3.3. Khóa đệ quy (recursive locking)

Khi sử dụng `std::mutex`, nếu thread đang cố gắng khóa mutex mà nó đã sở hữu (nghĩa là khóa mutex hai lần), điều này sẽ gây ra lỗi undefined behaviour. Nhưng trong một số trường hợp, có thể cần phải khóa mutex như vậy, ví dụ như hàm đệ quy:
```cpp
std::mutex mtx;
void recursive_function()
{
    mtx.lock()
    recursive_function();
    mtx.unlock();
}
```

Để giải quyết vấn đề này, C++ cung cấp `std::recursive_mutex`. Nó hoạt động giống như `std::mutex`, nhưng cho phép một luồng có thể `lock()` lại cùng một mutex nhiều lần mà không cần phải `unlock()` nó trước.
```cpp
#include <iostream>
#include <mutex>
std::recursive_mutex mtx;
void recursive_function(int count)
{
    if (count <= 0) return;
    mtx.lock();
    std::cout << "Locked " << count << std::endl;
    recursive_function(count - 1);
    mtx.unlock();
}
int main()
{
    recursive_function(3);
    return 0;
}
```

Mặc dù `std::recursive_mutex` có thể giải quyết một số tình huống mà `std::mutex` không thể xử lý, nhưng việc sử dụng `std::recursive_mutex` không được khuyến khích vì nó có thể khiến chúng ta có lối suy nghĩ cẩu thả và đưa ra những thiết kế thiếu chặt chẽ.

Ví dụ mã nguồn sử dụng `std::recursive_mutex` với `std::lock_guard`:
```cpp
#include <iostream>
#include <mutex>
class Counter
{
private:
    int value = 0;
    mutable std::recursive_mutex mtx;
public:
    void increment()
    {
        std::lock_guard<std::recursive_mutex> lock(mtx);
        value++;
        std::cout << "Value: " << value << std::endl;
    }
    void increment_twice()
    {
        std::lock_guard<std::recursive_mutex> lock(mtx);
        increment();
        increment();
    }
};
int main()
{
    Counter counter;
    counter.increment_twice();
    return 0;
}
```

Giải pháp tốt hơn mà không cần `std::recursive_mutex`:
```cpp
#include <iostream>
#include <mutex>
class Counter
{
private:
    int value = 0;
    mutable std::mutex mtx;
    void do_increment()
    {
        value++;
        std::cout << "Value: " << value << std::endl;
    }
public:
    void increment()
    {
        std::lock_guard<std::mutex> lock(mtx);
        do_increment();
    }
    void increment_twice()
    {
        std::lock_guard<std::mutex> lock(mtx);
        do_increment();
        do_increment();
    }
};
int main()
{
    Counter counter;
    counter.increment_twice();
    return 0;
}
```

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
