---
title: "Chương 4: Synchronizing concurrent operations"
description: Ghi chép trong quá trình đọc cuốn sách C++ Concurrency in Action của Anthony Williams
author: hoan9x
date: 2024-11-09 10:00:00 +0700
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

Cách tốt nhất là sử dụng *condition variable* (biến điều kiện) do C++ cung cấp để chờ đợi sự kiện. Khi một thread xác định điều kiện đã thỏa mãn, nó có thể thông báo cho các thread chờ để chúng tiếp tục xử lý mà không gây lãng phí tài nguyên.

### 1.1. Chờ đợi một sự kiện với condition variables



## 2. Tài liệu tham khảo

- [1] Anthony Williams, "4. Synchronizing concurrent operations" in *C++ Concurrency in Action*, 2nd Edition, 2019.
