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

Đặc điểm của objects:
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

> Ghi chú thú vị: Tác giả Anthony Williams đã gặp trường hợp undefined behavior khiến màn hình của một lập trình viên bốc cháy! Có thể đây chỉ mang tính cảnh báo hài hước, nhưng nó làm nổi bật mức độ nguy hiểm của lỗi này.
{: .prompt-info }

Cách tránh data race, nguyên nhân trực tiếp dẫn tới undefined behavior:
- Mutex (đã giới thiệu ở chương 3): Đồng bộ hóa giữa các thread, giúp giải quyết race condition, bao gồm cả data race.
- Atomic operations (sẽ giới thiệu ở chương này): Đồng bộ hóa các thao tác đọc/ghi (sửa đổi) trên dữ liệu, giúp tránh undefined behavior, nhưng không ngăn được race condition, vì thứ tự thứ tự sửa đổi (modification orders) vẫn chưa được xác định.

### 1.3. Modification orders

Mỗi object trong chương trình C++ có một modification order (thứ tự sửa đổi) bao gồm tất cả các thao tác write (ghi) vào object từ tất cả các threads, bắt đầu từ khi object được khởi tạo. Modification order có thể thay đổi giữa các lần chạy, nhưng trong mỗi lần thực thi, tất cả các threads phải đồng ý về thứ tự đó. Ví dụ trong chương trình dưới đây, kết quả của object data có thể thay đổi tùy theo modification order:
```cpp
#include <iostream>
#include <thread>
#include <mutex>
#include <chrono>
using namespace std::chrono_literals;
int main()
{
    uint8_t data{0};
    std::mutex mtx;

    std::thread th1([&]{
        std::this_thread::sleep_for(1ms);
        std::lock_guard<std::mutex> lk(mtx);
        data = 1;
    });
    std::thread th2([&]{
        std::this_thread::sleep_for(1ms);
        std::lock_guard<std::mutex> lk(mtx);
        data = 2;
    });
    std::thread th3([&]{
        std::this_thread::sleep_for(1ms);
        std::lock_guard<std::mutex> lk(mtx);
        data = 3;
    });
    th1.join();
    th2.join();
    th3.join();

    std::cout << "data=" << std::to_string(data) << std::endl;
}
```
Nếu object không phải là loại atomic, chương trình cần phải có cơ chế đồng bộ (như mutex) để các threads thống nhất về modification order của biến. Nếu không, data race sẽ xảy ra và dẫn đến undefined behavior. Nếu sử dụng atomic operations, compiler sẽ đảm bảo việc đồng bộ này.

Lưu ý rằng việc đồng bộ modification order chỉ giúp tránh data race, chứ không giải quyết vấn đề race condition. Trong ví dụ trên, mặc dù object data đã tránh được data race, nhưng modification order vẫn có thể thay đổi giữa các lần chạy, điều này có thể khiến logic của chương trình thay đổi không theo ý muốn.

## 2. Atomic operations và kiểu dữ liệu atomic

Atomic operation (thao tác nguyên tử) là thao tác không thể chia nhỏ, bạn không thể thấy thao tác đó đang được thực hiện dang dở từ bất kỳ thread nào, nghĩa là thao tác đó hoặc đã hoàn thành hoặc chưa hoàn thành. Trong C++, bạn cần sử dụng kiểu dữ liệu atomic để đảm bảo bạn đang sử dụng atomic operations.

### 2.1. Kiểu dữ liệu atomic tiêu chuẩn

Các kiểu dữ liệu atomic tiêu chuẩn được định nghĩa trong thư viện `<atomic>` của C++.

Bảng liệt kê một số kiểu atomic tiêu chuẩn và template `std::atomic<>` thay thế tương ứng:

| Atomic type            | Corresponding specialization      |
| ---------------------- | --------------------------------- |
| `std::atomic_bool`     | `std::atomic<bool>`               |
| `std::atomic_char`     | `std::atomic<char>`               |
| `std::atomic_schar`    | `std::atomic<signed char>`        |
| `std::atomic_uchar`    | `std::atomic<unsigned char>`      |
| `std::atomic_int`      | `std::atomic<int>`                |
| `std::atomic_uint`     | `std::atomic<unsigned>`           |
| `std::atomic_short`    | `std::atomic<short>`              |
| `std::atomic_ushort`   | `std::atomic<unsigned short>`     |
| `std::atomic_long`     | `std::atomic<long>`               |
| `std::atomic_ulong`    | `std::atomic<unsigned long>`      |
| `std::atomic_llong`    | `std::atomic<long long>`          |
| `std::atomic_ullong`   | `std::atomic<unsigned long long>` |
| `std::atomic_char16_t` | `std::atomic<char16_t>`           |
| `std::atomic_char32_t` | `std::atomic<char32_t>`           |
| `std::atomic_wchar_t`  | `std::atomic<wchar_t>`            |

Tất cả các thao tác `load()` (đọc), `store()` (ghi) trên các kiểu này đều là atomic operations.
```cpp
#include <iostream>
#include <thread>
#include <atomic>
#include <chrono>
using namespace std::chrono_literals;
int main()
{
    std::atomic_uint data{0};

    std::thread th1([&]{
        std::this_thread::sleep_for(1ms);
        data.store(1);
    });
    std::thread th2([&]{
        std::this_thread::sleep_for(1ms);
        data.store(2);
    });
    th1.join();
    th2.join();

    std::cout << "data=" << std::to_string(data.load()) << std::endl;
}
```

Thực ra, chúng ta có thể dùng mutex để làm cho các thao tác khác đọc/ghi trông giống như atomic operations:
```cpp
template <typename T>
class FakeAtomic
{
public:
    void store(const T &val)
    {
        std::lock_guard<std::mutex> lk(m_mut);
        m_data = val;
    }
    T load()
    {
        std::lock_guard<std::mutex> lk(m_mut);
        return m_data;
    }
private:
    T m_data;
    std::mutex m_mut;
};
```
Nếu tạo atomic operations sử dụng mutex nội bộ như trên, thì không có lợi ích gì về mặt hiệu suất chương trình, vì mutex thực chất là một cơ chế đồng bộ hóa ở mức cao hơn, không tận dụng được các lệnh atomic phần cứng.

Thật không may, không phải tất cả phần cứng đều hỗ trợ các thao tác atomic ở hardware-level, vì vậy không phải mọi kiểu atomic đều lock-free. Hầu hết các kiểu std::atomic đều có hàm thành viên `is_lock_free()` để kiểm tra kiểu dữ liệu atomic có thực sự lock-free hay không. Nếu `x.is_lock_free()` trả về `true`, phần cứng hiện tại của bạn hỗ trợ atomic type này, ngược lại, bạn nên chuyển qua dùng mutex cho kiểu dữ liệu bạn muốn bảo vệ.

Từ C++17, các kiểu `std::atomic` còn có thêm một biến thành viên static `is_always_lock_free` cho phép lập trình viên kiểm tra kiểu atomic đó có lock-free hay không tại thời điểm biên dịch (compile-time).

> Lưu ý, hàm thành viên `is_lock_free()` là để kiểm tra tại thời điểm runtime còn biến thành viên static `is_always_lock_free` kiểm tra tại thời điểm compile-time. Nghĩa là dùng `is_always_lock_free` thì compiler có thể tối ưu chương trình, giúp loại bỏ phần code không dùng tới.
{: .prompt-info }

Ví dụ khi compile chương trình sau, nếu `std::atomic<int>::is_always_lock_free` là `true` tại compile-time thì compiler có thể xóa luôn đoạn mã điều kiện để tối ưu:
```cpp
if (std::atomic<int>::is_always_lock_free) // Use atomic operations
else // Use mutex
```

Ngoài ra, C++11 còn cung cấp các macro [ATOMIC_*_LOCK_FREE](https://en.cppreference.com/w/c/atomic/ATOMIC_LOCK_FREE_consts) giúp xác định trạng thái lock-free của các kiểu atomic. Các macro này có thể trả về:
- 0: The atomic type is never lock-free => Cần cơ chế đồng bộ hóa khác chẳng hạn như mutex.
- 1: The atomic type is sometimes lock-free (Nghĩa là không thể xác định trong compile-time) => Giá trị này thường gặp khi không cấu hình biên dịch cho một kiến trúc vi xử lý cụ thể. Hoặc kiến trúc vi xử lý đó không hỗ trợ hoàn toàn các phép toán atomic lock-free, hay chỉ hỗ trợ trong một số tình huống.
- 2: The atomic type is always lock-free.

`std::atomic_flag` là kiểu atomic duy nhất không có hàm thành viên `is_lock_free()`. Nó là một cờ `Boolean` đơn giản và luôn lock-free. Bạn có thể sử dụng nó để triển khai các kiểu atomic khác. Các đối tượng `std::atomic_flag` được khởi tạo là "clear", và chỉ có thể được truy vấn và thiết lập bằng `test_and_set()` hoặc xóa bằng `clear()`.

Mỗi atomic operation như `store()/load()` có một tham số tuỳ chọn gọi là memory-ordering. Tham số này được sử dụng để chỉ định cách thức sắp xếp bộ nhớ, và nó có thể là một trong các giá trị [`enum std::memory_order`](https://en.cppreference.com/w/cpp/atomic/memory_order).

Các giá trị enum được phép đặt cho memory-ordering phụ thuộc vào loại atomic operation. Nếu không đặt giá trị ordering, mặc định sẽ là `std::memory_order_seq_cst` (đây là kiểu sắp xếp mạnh nhất).

Giá trị enum được phép đặt cho memory-ordering của các atomic operation cơ bản như sau:
- Store operations: `memory_order_relaxed`, `memory_order_release`, `memory_order_seq_cst`.
- Load operations: `memory_order_relaxed`, `memory_order_consume`, `memory_order_acquire`, `memory_order_seq_cst`.
- Read-modify-write operations: `memory_order_relaxed`, `memory_order_consume`, `memory_order_acquire`, `memory_order_release`, `memory_order_acq_rel`, `memory_order_seq_cst`.

### 2.2. Thao tác với `std::atomic_flag`

`std::atomic_flag` là kiểu dữ liệu atomic đơn giản nhất, chỉ có hai trạng thái: `set` và `clear`. Nó phải được khởi tạo với `ATOMIC_FLAG_INIT` và không thể sao chép hoặc gán. Các thao tác có thể thực hiện với `std::atomic_flag` là `clear()` xóa, `test_and_set()` đặt và truy vấn giá trị cũ, `destructor` hủy nó.

Ví dụ gọi `clear()` để `std::atomic_flag` được xóa với memory-ordering là `release`, trong khi `test_and_set()` sử dụng memory-ordering mặc định là `seq_cst`.
```cpp
f.clear(std::memory_order_release);
bool x = f.test_and_set();
```

Vì tính đơn giản và hạn chế, `std::atomic_flag` rất phù hợp để sử dụng làm spinlock mutex. Ví dụ:
```cpp
class spinlock_mutex
{
    std::atomic_flag flag;
public:
    spinlock_mutex(): flag(ATOMIC_FLAG_INIT) {}
    void lock()
    {
      while (flag.test_and_set(std::memory_order_acquire));
    }
    void unlock()
    {
      flag.clear(std::memory_order_release);
    }
};
```
Spinlock mutex trên đủ để sử dụng với `std::lock_guard<spinlock_mutex>`. Tuy nhiên, nó thực hiện một busy-wait trong `lock()`, vì vậy đây không phải là lựa chọn tốt cho các tình huống có độ tranh chấp cao.

| Tiêu chí       | Spinlock mutex                       | Mutex thông thường                     |
| -------------- | ------------------------------------ | -------------------------------------- |
| Cách thức chờ  | Vòng chờ (busy-wait)                 | Tạm dừng (blocked)                     |
| Tài nguyên CPU | Tốn tài nguyên CPU nếu có tranh chấp | Không tốn tài nguyên CPU khi chờ       |
| Hiệu quả       | Thích hợp cho tranh chấp ngắn hạn    | Thích hợp cho tranh chấp dài hạn       |
| Phù hợp khi    | Khóa mutex trong thời gian ngắn      | Khóa mutex trong thời gian dài         |
| Độ phức tạp    | Đơn giản                             | Phức tạp hơn (sử dụng cơ chế tạm dừng) |

### 2.3. Thao tác với `std::atomic<bool>`

`std::atomic<bool>` là một biến boolean hoàn chỉnh hơn so với `std::atomic_flag`. Mặc dù không thể khởi tạo sao chép (copy-constructible) hay gán sao chép (copy-assignable), bạn vẫn có thể khởi tạo nó từ một giá trị `bool` thông thường, và có thể gán giá trị cho đối tượng `std::atomic<bool>` từ một `bool` không phải atomic:
```cpp
std::atomic<bool> b(true);
b = false;
```

Khi gán giá trị từ một `bool` không phải atomic, toán tử gán trả về giá trị `bool` đã được gán thay vì trả về một tham chiếu tới đối tượng (đọc kỹ hơn `operator=` của atomic [ở đây](https://en.cppreference.com/w/cpp/atomic/atomic/operator%3D)). Điều này giúp tránh phải tải lại giá trị từ bộ nhớ trong trường hợp có thay đổi từ các luồng khác.

Việc đọc/ghi giá trị `true/false` cho `std::atomic<bool>` có thể được thực hiện bằng `load()` và `store()`, cũng như bạn có thể chỉ định các semantic bộ nhớ cho hành động đọc/ghi (ở đây "semantic bộ nhớ" và "memory-ordering" tương đương nhau đều ám chỉ các cách thức kiểm soát thứ tự thực thi và đồng bộ hóa bộ nhớ giữa các phép toán atomic). Ví dụ:

```cpp
std::atomic<bool> b;
bool x = b.load(std::memory_order_acquire);
b.store(true);
x = b.exchange(false, std::memory_order_acq_rel);
```

Hàm `exchange()` là một thao tác read-modify-write (trả về giá trị hiện tại và ghi giá trị mới), nó thay thế cho `test_and_set()` trong `std::atomic_flag`.

`std::atomic<bool>` cũng hỗ trợ thao tác so sánh và gán giá trị mới nếu giá trị hiện tại bằng một giá trị kỳ vọng. Thao tác này gọi là [`compare-exchange`](https://en.cppreference.com/w/cpp/atomic/atomic/compare_exchange), bao gồm các hàm `compare_exchange_weak()` và `compare_exchange_strong()`:
- `compare_exchange_weak()` có thể không thành công dù giá trị ban đầu của `atomic` bằng giá trị kỳ vọng `expected`, điều này xảy ra khi có spurious failure (lỗi giả) do điều kiện hệ thống (ví dụ như chuyển luồng trong khi thực hiện thao tác). Do đó, cần sử dụng `compare_exchange_weak()` trong vòng lặp.
- `compare_exchange_strong()` đảm bảo rằng nếu giá trị không khớp với giá trị kỳ vọng, nó sẽ trả về `false` và không gặp phải các lỗi giả như `compare_exchange_weak()`.

Ví dụ `compare_exchange_weak()`:
```cpp
bool expected = false;
extern atomic<bool> b; // b is set somewhere else
while(!b.compare_exchange_weak(expected, true) && !expected);
```
- Chú ý: Hàm `compare_exchange_weak(expected, true)` có tham số thứ nhất `expected` được **pass by reference**. Nó so sánh giá trị hiện tại của `b` với `expected`:
   + Nếu giá trị hiện tại của `b` khác với `expected` (tức là `b!=expected`), thì `expected` sẽ được cập nhật thành giá trị hiện tại của `b`. Ví dụ, nếu `b` đã là `true`, thì `expected` sẽ trở thành `true`.
   + Nếu giá trị hiện tại của `b` bằng `expected` (tức là `b==expected`, ví dụ cả `b` và `expected` đều là `false`), thì `compare_exchange_weak()` sẽ cố gắng thay đổi giá trị của biến `b` từ `false` thành `true`.
- Hàm `compare_exchange_weak()` sẽ trả về `true` nếu giá trị của `b` được thay đổi thành công, và trả về `false` nếu không thay đổi được giá trị.

Các hàm `compare-exchange` có điểm đặc biệt là chúng có thể nhận hai tham số về memory-order khác nhau trong trường hợp thay đổi thành công và thất bại. Những hậu quả của việc lựa chọn memory ordering sẽ giải thích ở mục 5.3.

Cuối cùng, `std::atomic<bool>` có hàm thành viên `is_lock_free()` để kiểm tra xem các hoạt động trên nó có lock-free hay không.

### 2.4. Thao tác với atomic con trỏ `std::atomic<T*>`

Thao tác với `std::atomic<T*>` tương tự như `std::atomic<bool>`. Nhưng lưu ý, thao tác với atomic con trỏ sẽ trả về giá trị kiểu con trỏ `T*` thay vì `bool`. Ngoài ra, `std::atomic<T*>` sẽ có các thao tác mới để hoạt động với con trỏ là `fetch_add()` và `fetch_sub()`, nó thực hiện cộng/trừ atomic trên địa chỉ của con trỏ.

<!-- `std::atomic<T*>` cũng có sẵn các toán tử `+=`, `-=`, `++` và `--`. Các toán tử này hoạt động như sau: nếu có `std::atomic<Foo*> x;` trỏ đến phần tử đầu tiên của một mảng các đối tượng `Foo`, thì `x+=3` sẽ thay đổi nó để trỏ đến phần tử thứ tư và trả về một con trỏ kiểu `Foo*` trỏ đến phần tử thứ tư đó.

fetch_add() và fetch_sub() hơi khác một chút vì chúng trả về giá trị ban đầu (do đó x.fetch_add(3) sẽ cập nhật x để trỏ đến giá trị thứ tư nhưng trả về một con trỏ đến giá trị đầu tiên trong mảng). Thao tác này còn được gọi là exchange-and-add, và đó là một phép toán read-modify-write nguyên tử, giống như exchange() và compare_exchange_weak()/compare_exchange_strong(). Giống như các phép toán khác, giá trị trả về là một giá trị con trỏ kiểu T* thay vì tham chiếu đến đối tượng std::atomic<T*>, vì vậy mã gọi có thể thực hiện các hành động dựa trên giá trị trước đó:

```cpp
class Foo{};
Foo some_array[5];
std::atomic<Foo*> p(some_array);
Foo* x = p.fetch_add(2); // Cộng 2 vào p và trả về giá trị cũ
assert(x == some_array);
assert(p.load() == &some_array[2]);
x = (p -= 1); // Trừ 1 từ p và trả về giá trị mới
assert(x == &some_array[1]);
assert(p.load() == &some_array[1]);
```

Các dạng hàm này cũng cho phép chỉ định các semantics về thứ tự bộ nhớ như một tham số hàm bổ sung:

```cpp
p.fetch_add(3, std::memory_order_release);
```

Vì cả fetch_add() và fetch_sub() đều là các phép toán read-modify-write, chúng có thể có bất kỳ thẻ thứ tự bộ nhớ nào và có thể tham gia vào một chuỗi release. Tuy nhiên, việc chỉ định thứ tự bộ nhớ không thể thực hiện cho các dạng toán tử, vì không có cách nào để cung cấp thông tin đó: do đó, các dạng toán tử này luôn có semantics memory_order_seq_cst.

Các kiểu nguyên tử cơ bản còn lại đều giống nhau: tất cả chúng đều là các kiểu số nguyên tử và có cùng giao diện với nhau, ngoại trừ việc kiểu dữ liệu tích hợp đi kèm khác nhau. Chúng ta sẽ xem xét chúng như một nhóm. -->

## 3. Tài liệu tham khảo

- [1] Anthony Williams, "5. The C++ memory model and operations on atomic types" in *C++ Concurrency in Action*, 2nd Edition, 2019.

[//]: # (----------LIST OF IMAGES----------)
[img_1]: /assets/img/2024-12-CXX-concurrency-chap-5/01_division_of_struct_into_objects_and_memory_locations.png "Phân chia struct thành các objects và memory locations"
[img_1d]: /assets/img/2024-12-CXX-concurrency-chap-5/01d_division_of_struct_into_objects_and_memory_locations.png "Phân chia struct thành các objects và memory locations"
