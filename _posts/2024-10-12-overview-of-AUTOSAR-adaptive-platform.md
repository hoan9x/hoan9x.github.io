---
title: Tổng quan về AUTOSAR adaptive platform
description: Tổng quan về thiết kế tổng thể của AP và các khái niệm chính
author: hoan9x
date: 2024-10-12 22:00:00 +0700
categories: [AUTOSAR, Adaptive Platform]
---

## Bối cảnh ra đời một ECU thông minh

Phần mềm trong các ECU nhúng truyền thống thường được thiết kế và triển khai cho xe mà không cần cập nhật gì đáng kể trong suốt vòng đời của chúng. Các phần mềm này thường kiểm soát tín hiệu đầu ra dựa trên tín hiệu đầu vào (ví dụ: Airbag ECU) và thông tin từ các ECU có thể được kết nối với mạng lưới trong xe như CAN (Controller Area Network).

Hiện nay, xu hướng của xe tự hành (auto driving, driver assistance), nhu cầu giải trí khi lái xe (video playback, multimedia) và khả năng điều khiển mọi thứ từ xa (IoT, Wi-Fi, LTE, GPS) khiến lập trình phần mềm cho xe trở nên phức tạp. Các phần mềm này đòi hỏi nhiều tài nguyên tính toán, yêu cầu nghiêm ngặt về bảo mật cũng như tính toàn vẹn dữ liệu. Như vậy, phần mềm sẽ có nhu cầu cần được cập nhật trong suốt vòng đời của xe để cải thiện.

Tiêu chuẩn AUTOSAR classic platform (CP) giải quyết các nhu cầu cần cho ECU nhúng truyền thống rất tốt, nhưng không thể đáp ứng được với xu hướng hiện tại. Do đó, AUTOSAR adaptive platform (AP) ra đời. AP cung cấp các cơ chế truyền thông và tính toán hiệu suất cao, cũng như khả năng cấu hình, cập nhật phần mềm một cách linh hoạt.

## Công nghệ thúc đẩy nền tảng mới

Ethernet (mạng máy tính) và Processor (bộ xử lý) là hai nhóm công nghệ chính đằng sau của AP. Như đã trình bày ở trên, xu hướng của xe tự hành, nhu cầu giải trí... làm cho băng thông mạng được sử dụng nhiều hơn. Chuẩn giao tiếp CAN không còn phù hợp nữa, dẫn đến sự ra đời của Ethernet. CP mặc dù cũng hỗ trợ Ethernet, nhưng chủ yếu chỉ được thiết kết tối ưu với các chuẩn giao tiếp cũ, khó tận dụng và hưởng lợi đầy đủ từ khả năng giao tiếp dựa trên Ethernet mới hơn.

Tương tự với lý do ở trên, yêu cầu về hiệu suất của Processor đã tăng lên rất nhiều trong những năm gần đây khi xe càng trở nên thông minh hơn. Multicore processors (bộ xử lý đa lõi) đã được sử dụng với CP, nhưng nhu cầu về sức mạnh xử lý đòi hỏi nhiều hơn là đa lõi, mà có thể lên đến hàng chục, hàng trăm lõi (manycore processors). Ví dụ: GPGPU (General Purpose use of GPU), FPGA đang nổi lên vì chúng cung cấp hiệu suất cao hơn gấp bội so với các MCU thông thường. Số lượng lõi xử lý ngày càng tăng làm cho thiết kế của CP trở lên quá tải. Những kết hợp của sức mạnh xử lý lớn hơn và giao tiếp nhanh hơn thúc đẩy sự ra đời của AP.

## Đặc điểm của AP

- Lập trình bằng C++: Vì đây là ngôn ngữ được lựa chọn để phát triển các thuật toán và phần mềm ứng dụng mới trong các ứng dụng phức tạp, quan trọng về hiệu suất.
- Kiến ​​trúc hướng dịch vụ (SOA - Service Oriented Architecture): Là một kiến trúc điện toán phân tán (distributed computing), nó hỗ trợ các ứng dụng phức tạp, đồng thời cho phép tính linh hoạt và khả năng mở rộng. Kiến trúc này cũng hưởng lợi từ sự nâng cấp băng thông nhanh và rộng như Ethernet.
- 
