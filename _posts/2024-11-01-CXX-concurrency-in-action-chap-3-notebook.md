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
