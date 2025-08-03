---
title: '[Vector & python-can] Thiết lập môi trường mô phỏng cho giao tiếp CAN'
description: Bài viết này sẽ hướng dẫn bạn cách thiết lập Vector Virtual CAN Bus và dùng python-can để mô phỏng giao tiếp CAN
author: hoan9x
date: 2025-08-02 10:00:00 +0700
categories: [Communication protocol, CAN]
mermaid: true
---

Trước đây, khi làm việc với giao tiếp CAN, tôi từng nhận task viết một tool chạy trên Windows để đọc dữ liệu từ ECU qua CAN Bus. Lúc đó, hệ thống test dùng Vector device (một dạng USB-to-CAN chuyên dụng) để kết nối với ECU.

![light mode only][img_1]{: width="607" height="441" .light }
![dark mode only][img_1d]{: width="607" height="441" .dark }

Tuy nhiên, do cả Vector device và ECU đều là thiết bị dùng chung giữa nhiều team, nên mỗi lần kiểm tra hoặc chỉnh sửa tool đều rất bất tiện. Để giải quyết, tôi đã tìm cách dựng môi trường mô phỏng qua Virtual CAN Bus, cho phép phát triển và kiểm thử hoàn toàn độc lập mà không cần đến phần cứng thực.

## 1. Cài đặt Vector Virtual CAN Bus

**Bước 1: Tải và cài đặt Vector Driver mới nhất [ở đây](https://www.vector.com/latest_driver).**

Hệ điều hành của tôi là Windows 11 nên chọn tải như hình dưới (lưu ý phiên bản trong tương lai có thể thay đổi, nhưng bạn cứ cài đặt phiên bản mới nhất).

![light mode only][img_2]{: width="729" height="529" .light }
![dark mode only][img_2d]{: width="729" height="529" .dark }

Sau khi tải, ta sẽ được một file .zip, giải nén nó và nhấn vào "setup.exe".

![Desktop View][img_3]{: width="616" height="111" .center }

Khi popup này hiện ra, hãy chọn đúng Vector device family mà sau này bạn sử dụng để kết nối tới ECU thật.
Hiện tại, vì chỉ thiết lập môi trường mô phỏng thì bạn không cần quan tâm tới các tùy chọn này lắm.

![light mode only][img_4]{: width="387" height="525" .light }
![dark mode only][img_4d]{: width="387" height="525" .dark }

Cài đặt Vector Driver thành công là xong bước 1.

![light mode only][img_5]{: width="402" height="314" .light }
![dark mode only][img_5d]{: width="402" height="314" .dark }

**Bước 2: Tải và cài đặt XL Driver Library mới nhất [ở đây](https://www.vector.com/xl-lib/11/).**

Để tải XL Driver Library, bạn cần điền vào một form cung cấp thông tin để Vector gửi link tải về qua email.
Driver này đi kèm với một số điều khoản sử dụng quan trọng (bạn nên đọc kỹ bản chính thức từ Vector), có thể tóm lược như sau:
 + Không được phép phân phối lại XL Driver Library dưới dạng thư viện DLL, trừ khi có thỏa thuận bằng văn bản với Vector.
 + Không được sử dụng trong các hệ thống đòi hỏi độ an toàn cao như thiết bị y tế, quân sự, hàng không, năng lượng hạt nhân, v.v.
 + Vector không cam kết bảo trì, cập nhật hay sửa lỗi cho thư viện này. Do được cung cấp miễn phí theo nguyên tắc "as-is", người dùng cần tự chịu trách nhiệm kiểm tra và thử nghiệm kỹ lưỡng nếu muốn tích hợp vào hệ thống của mình.

![light mode only][img_6]{: width="726" height="475" .light }
![dark mode only][img_6d]{: width="726" height="475" .dark }

Sau khi tải XL Driver Library, ta sẽ được một file .zip, giải nén nó và nhấn vào "Vector XL Driver Library Setup.exe".

![Desktop View][img_7]{: width="623" height="91" .center }

Cài đặt XL Driver Library thành công là xong bước 2.

![light mode only][img_8]{: width="500" height="381" .light }
![dark mode only][img_8d]{: width="500" height="381" .dark }

**Bước 3: Cấu hình Application trong Vector Hardware Config.**

Sau khi hoàn thành bước 1 và bước 2, trong Windows Start sẽ có các phần mềm sau của Vector:
 + Vector Hardware Configuration: Đây là công cụ giúp bạn chọn và gán tên cho các cổng CAN/LIN trên Vector device (như [VN1630](https://www.vector.com/gb/en/products/products-a-z/hardware/network-interfaces/vn16xx/#)) để máy tính có thể nhận diện và sử dụng chúng đúng cách.
 + Vector Hardware Manager: Đây là phiên bản kế nhiệm hiện đại hơn của Vector Hardware Configuration.

![Desktop View][img_9]{: width="320" height="198" .center }

Hãy mở Vector Hardware Configuration để cấu hình Application.

![light mode only][img_10]{: width="605" height="417" .light }
![dark mode only][img_10d]{: width="605" height="417" .dark }

Trong Vector Hardware Configuration, hãy nhấp chuột phải vào mục Application và chọn Add Application.
Khi popup sau xuất hiện, bạn chỉ cần điền Application Name và chọn 1 CAN channel là đủ.

![light mode only][img_11]{: width="421" height="339" .light }
![dark mode only][img_11d]{: width="421" height="339" .dark }

Sau khi tạo Application, bạn cần gán một CAN Bus cho nó.
Vì hiện tại không có Vector device thật được kết nối, nên Vector Hardware Config sẽ không hiển thị các CAN Bus vật lý. Thay vào đó, bạn có thể gán một CAN Virtual Bus để mô phỏng môi trường giao tiếp ảo.

![light mode only][img_12]{: width="605" height="417" .light }
![dark mode only][img_12d]{: width="605" height="417" .dark }

Gán CAN Virtual Bus cho Application thành công là xong bước 3.

![light mode only][img_13]{: width="605" height="417" .light }
![dark mode only][img_13d]{: width="605" height="417" .dark }

Lưu ý: Trong tương lai, Vector Hardware Configuration có thể sẽ không còn được hỗ trợ. Khi đó, bạn có thể sử dụng Vector Hardware Manager để thay thế trong việc cấu hình.

![light mode only][img_14]{: width="903" height="475" .light }
![dark mode only][img_14d]{: width="903" height="475" .dark }

## 2. Cài đặt python-can và kết nối tới Vector Virtual CAN Bus

Dùng lệnh sau để cài đặt python-can:
```bash
$ pip install python-can
```

Sau khi đã cài đặt python-can, hãy tạo một script python đơn giản có nội dung như sau:
```python
import can

bus = can.interface.Bus(interface='vector',
                        channel=0,
                        bitrate=500000,
                        app_name='App-Python-CAN')
message = can.Message(arbitration_id=0x1A,
                      data=[1, 2, 3, 4, 5, 6, 7, 8])
bus.send(message)
bus.shutdown()
```
Lưu ý hãy dùng `app_name` giống với Application Name đã cấu hình trong Vector Hardware Configuration.

> Application Name trong Vector là một khái niệm logic dùng để ánh xạ phần mềm với các cổng truyền thông vật lý hoặc ảo (CAN, LIN, FlexRay, Ethernet), giúp quản lý cấu hình giao tiếp một cách linh hoạt và thống nhất.
{: .prompt-tip }

## 3. Gửi một CAN message bằng python-can và kiểm tra nó.

Để quan sát CAN message được truyền trong bus, tôi sẽ dùng [BUSMASTER](https://rbei-etas.github.io/busmaster/).
Bạn có thể tải BUSMASTER hoặc bất kỳ phần mềm nào khác cũng được. Và các bước tải và cài đặt BUSMASTER khá đơn giản nên tôi sẽ không đề cập nhiều ở đây.

![Desktop View][img_15]{: width="672" height="721" .center }

Hình GIF trên minh họa quá trình tôi sử dụng BUSMASTER để kết nối tới Vector XL nhằm quan sát các CAN message. Tôi đã dùng một đoạn script Python để truyền dữ liệu vào Vector CAN Virtual Bus. Như bạn có thể thấy, các cột CAN ID và Data Byte(s) trong BUSMASTER hiển thị chính xác nội dung tôi đã gửi từ script.

> Trong script Python, tôi gửi dữ liệu qua `channel=0`, nhưng trong BUSMASTER, cột Channel lại hiển thị là 1 - điều này là bình thường vì BUSMASTER và Vector Hardware Config đánh số kênh bắt đầu từ 1, còn trong Python thì bắt đầu từ 0.
{: .prompt-info }

## 4. Tài liệu tham khảo

- [1] Python‑can documentation [Online]. Available: [link](https://python-can.readthedocs.io/en/stable/)
- [2] Article. (2021). *【Vector Virtual CAN BUS & Python-can】CAN通信のシミュレーション環境構築* [Online]. Available: [link](https://kakitamablog.com/can-communication-python-can/).


[//]: # (----------SCOPE OF DECLARATION OF LIST OF IMAGES USED IN POST----------)
[img_1]: /assets/img/2025-08-Python-Can-Vector-setup-CAN-simulation-environment/01_model_vector_can_bus.png "Mô hình kết nối Vector device và ECU"
[img_1d]: /assets/img/2025-08-Python-Can-Vector-setup-CAN-simulation-environment/01d_model_vector_can_bus.png "Mô hình kết nối Vector device và ECU"
[img_2]: /assets/img/2025-08-Python-Can-Vector-setup-CAN-simulation-environment/02_vector_driver.png "Tải Vector Driver"
[img_2d]: /assets/img/2025-08-Python-Can-Vector-setup-CAN-simulation-environment/02d_vector_driver.png "Tải Vector Driver"
[img_3]: /assets/img/2025-08-Python-Can-Vector-setup-CAN-simulation-environment/03_setup_exe_click.png "Nhấn setup.exe"
[img_4]: /assets/img/2025-08-Python-Can-Vector-setup-CAN-simulation-environment/04_setup_vector_driver.png "Chọn Vector device family"
[img_4d]: /assets/img/2025-08-Python-Can-Vector-setup-CAN-simulation-environment/04d_setup_vector_driver.png "Chọn Vector device family"
[img_5]: /assets/img/2025-08-Python-Can-Vector-setup-CAN-simulation-environment/05_setup_vector_driver_done.png "Cài đặt Vector Driver thành công"
[img_5d]: /assets/img/2025-08-Python-Can-Vector-setup-CAN-simulation-environment/05d_setup_vector_driver_done.png "Cài đặt Vector Driver thành công"
[img_6]: /assets/img/2025-08-Python-Can-Vector-setup-CAN-simulation-environment/06_vector_xl_driver_library.png "Tải Driver XL Library"
[img_6d]: /assets/img/2025-08-Python-Can-Vector-setup-CAN-simulation-environment/06d_vector_xl_driver_library.png "Tải Driver XL Library"
[img_7]: /assets/img/2025-08-Python-Can-Vector-setup-CAN-simulation-environment/07_vector_xl_driver_exe_click.png "Nhấn setup.exe"
[img_8]: /assets/img/2025-08-Python-Can-Vector-setup-CAN-simulation-environment/08_vector_xl_driver_setup_done.png "Cài đặt Driver XL Library thành công"
[img_8d]: /assets/img/2025-08-Python-Can-Vector-setup-CAN-simulation-environment/08d_vector_xl_driver_setup_done.png "Cài đặt Driver XL Library thành công"
[img_9]: /assets/img/2025-08-Python-Can-Vector-setup-CAN-simulation-environment/09_vector_hardware_config.png "Vector Hardware Config"
[img_10]: /assets/img/2025-08-Python-Can-Vector-setup-CAN-simulation-environment/10_add_application_in_vector_hardware_config.png "Thêm Application trong Vector Hardware Config"
[img_10d]: /assets/img/2025-08-Python-Can-Vector-setup-CAN-simulation-environment/10d_add_application_in_vector_hardware_config.png "Thêm Application trong Vector Hardware Config"
[img_11]: /assets/img/2025-08-Python-Can-Vector-setup-CAN-simulation-environment/11_application_setup.png "Thiết lập Application"
[img_11d]: /assets/img/2025-08-Python-Can-Vector-setup-CAN-simulation-environment/11d_application_setup.png "Thiết lập Application"
[img_12]: /assets/img/2025-08-Python-Can-Vector-setup-CAN-simulation-environment/12_set_virtual_can_bus_for_application.png "Thiết lập CAN Virtual Bus cho Application"
[img_12d]: /assets/img/2025-08-Python-Can-Vector-setup-CAN-simulation-environment/12d_set_virtual_can_bus_for_application.png "Thiết lập CAN Virtual Bus cho Application"
[img_13]: /assets/img/2025-08-Python-Can-Vector-setup-CAN-simulation-environment/13_set_virtual_can_bus_done.png "Hoàn thành thiết lập CAN Virtual Bus cho Application"
[img_13d]: /assets/img/2025-08-Python-Can-Vector-setup-CAN-simulation-environment/13d_set_virtual_can_bus_done.png "Hoàn thành thiết lập CAN Virtual Bus cho Application"
[img_14]: /assets/img/2025-08-Python-Can-Vector-setup-CAN-simulation-environment/14_hardware_manager.png "Vector Hardware Manager"
[img_14d]: /assets/img/2025-08-Python-Can-Vector-setup-CAN-simulation-environment/14d_hardware_manager.png "Vector Hardware Manager"
[img_15]: /assets/img/2025-08-Python-Can-Vector-setup-CAN-simulation-environment/15_python_can_vector_demo.gif "Python CAN Vector Demo"
