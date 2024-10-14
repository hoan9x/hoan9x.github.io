---
title: Tổng quan về AUTOSAR adaptive platform
description: Tổng quan về thiết kế tổng thể của AP và các khái niệm chính
author: hoan9x
date: 2024-11-30 22:00:00 +0700
categories: [Automotive, AUTOSAR AP]
---

## 1. Phạm vi kỹ thuật và cách tiếp cận

### 1.1. Bối cảnh ra đời một ECU thông minh

Phần mềm trong các ECU nhúng truyền thống thường được thiết kế và triển khai cho xe mà không cần cập nhật gì đáng kể trong suốt vòng đời của chúng. Các phần mềm này thường kiểm soát tín hiệu đầu ra dựa trên tín hiệu đầu vào (ví dụ: Airbag ECU) và thông tin từ các ECU có thể được kết nối với mạng lưới trong xe như CAN (Controller Area Network).

Hiện nay, xu hướng của xe tự hành (auto driving, driver assistance), nhu cầu giải trí khi lái xe (video playback, multimedia) và khả năng điều khiển mọi thứ từ xa (IoT, Wi-Fi, LTE, GPS) khiến lập trình phần mềm cho xe trở nên phức tạp. Các phần mềm này đòi hỏi nhiều tài nguyên tính toán, yêu cầu nghiêm ngặt về bảo mật cũng như tính toàn vẹn dữ liệu. Như vậy, phần mềm sẽ có nhu cầu cần được cập nhật trong suốt vòng đời của xe để cải thiện.

Tiêu chuẩn AUTOSAR classic platform (CP) giải quyết các nhu cầu cần cho ECU nhúng truyền thống rất tốt, nhưng không thể đáp ứng được với xu hướng hiện tại. Do đó, AUTOSAR adaptive platform (AP) ra đời. AP cung cấp các cơ chế truyền thông và tính toán hiệu suất cao, cũng như khả năng cấu hình, cập nhật phần mềm một cách linh hoạt.

### 1.2. Công nghệ thúc đẩy nền tảng mới

Ethernet (mạng máy tính) và Processor (bộ xử lý) là hai nhóm công nghệ chính đằng sau của AP. Như đã trình bày ở trên, xu hướng của xe tự hành, nhu cầu giải trí... làm cho băng thông mạng được sử dụng nhiều hơn. Chuẩn giao tiếp CAN không còn phù hợp nữa, dẫn đến sự ra đời của Ethernet. CP mặc dù cũng hỗ trợ Ethernet, nhưng chủ yếu chỉ được thiết kết tối ưu với các chuẩn giao tiếp cũ, khó tận dụng và hưởng lợi đầy đủ từ khả năng giao tiếp dựa trên Ethernet mới hơn.

Tương tự với lý do ở trên, yêu cầu về hiệu suất của Processor đã tăng lên rất nhiều trong những năm gần đây khi xe càng trở nên thông minh hơn. Multicore processors (bộ xử lý đa lõi) đã được sử dụng với CP, nhưng nhu cầu về sức mạnh xử lý đòi hỏi nhiều hơn là đa lõi, mà có thể lên đến hàng chục, hàng trăm lõi (manycore processors). Ví dụ: GPGPU (General Purpose use of GPU), FPGA đang nổi lên vì chúng cung cấp hiệu suất cao hơn gấp bội so với các MCU thông thường. Số lượng lõi xử lý ngày càng tăng làm cho thiết kế của CP trở lên quá tải. Những kết hợp của sức mạnh xử lý lớn hơn và giao tiếp nhanh hơn thúc đẩy sự ra đời của AP.

### 1.3. Đặc điểm của AP

- Lập trình bằng C++: Vì đây là ngôn ngữ được lựa chọn để phát triển các thuật toán và phần mềm quan trọng về hiệu suất.
- SOA (Service Oriented Architecture - kiến ​​trúc hướng dịch vụ): Là một kiến trúc điện toán phân tán (distributed computing), nó hỗ trợ các ứng dụng phức tạp, đồng thời cho phép tính linh hoạt và khả năng mở rộng. Kiến trúc này cũng hưởng lợi từ sự nâng cấp băng thông nhanh và rộng như ethernet.
- Parallel processing (xử lý song song): Vì SOA là kiến trúc tính toán phân tán các dịch vụ, nên AP phải có tính xử lý song song. Xử lý song song còn để khai thác sức mạnh, tăng hiệu suất khi triển khai trên các kiến trúc phần cứng manycore.
- Leveraging existing standard (tận dụng tiêu chuẩn hiện có): AP sẽ tận dụng lại các tiêu chuẩn sẵn có để đảm bảo khả năng tương thích ngược, cũng như để đẩy nhanh việc phát triển và hưởng lợi những điểm tốt của các tiêu chuẩn này.<br>
Ví dụ:
1. AP sử dụng POSIX (là các interface tiêu chuẩn của hệ điều hành, đảm bảo AP có thể chạy trên các hệ điều hành hỗ trợ POSIX).
2. AP sử dụng ngôn ngữ lập trình theo tiêu chuẩn C++11/14.
3. AP sử dụng chuẩn giao tiếp mạng IP.
- Safety and security (an toàn và bảo mật).
- Planned dynamics: AP được thiết kế có tính động (dynamic) và linh hoạt (flexibility).<br>
Ví dụ:
1. Linh động trong việc cập nhật phần mềm: Đây là nhu cầu để AP ra đời và cũng là đặc điểm mà AP phải hướng tới.
2. Tự động khám phá các dịch vụ: AP là nền tảng có kiến trúc hướng dịch vụ, việc tự động khám phá các dịch vụ rất quan trọng với các hệ thống có nhiều dịch vụ.
3. Cấu hình linh động: Bạn có thể điều chỉnh các thông số cho AP trong quá trình vận hành.
- Agile (là một phương pháp phát triển phần mềm linh hoạt): Bạn có thể hiểu Agile là một khuôn khổ quản lý dự án để tiêu chuẩn hóa toàn bộ quy trình phát triển phần mềm. AP hướng đến mục tiêu thích ứng với mọi quy trình phát triển, đặc biệt là Agile vì AP có kiến trúc cơ bản của hệ thống có khả năng mở rộng, cũng như khả năng cập nhật hệ thống một cách linh động.

### 1.4. Kiến trúc kết hợp các nền tảng khác nhau

Như đã mô tả ở phần trước, AP sẽ cố gắng tận dụng những tiêu chuẩn hiện có, nghĩa là nó sẽ không thay thế hoàn toàn các nền tảng khác như CP hoặc Non-AUTOSAR (nền tảng không theo tiêu chuẩn AUTOSAR). Thay vào đó, nó sẽ tương tác với các nền tảng đó để tạo thành một hệ thống tích hợp.

![light mode only][img_1]{: width="800" height="420" .light }
![dark mode only][img_1d]{: width="800" height="420" .dark }

Hệ thống điện trong các mẫu xe hiện đại thường bao gồm rất nhiều ECU để xử lý các chức năng khác nhau, và AUTOSAR hướng tới kiến trúc kết hợp các nền tảng. Như hình trên, các ECUs có thể chạy CP, AP hoặc Non-AUTOSAR, và chúng được kết nối chung một bus mạng (CAN, Ethernet, ..) để có thể giao tiếp liền mạch.

> Vì sao không để AP thay thế hoàn toàn các nền tảng khác?
> - Vì một số lý do sau:
>   - Bổ sung thế mạch: CP được sử dụng cho các nhiệm vụ thời gian thực (hard real-time), có tính an toàn và ổn định cao. Trong khi đó AP được sử dụng cho các chức năng tiên tiến như hệ thống giải trí, tự hành (ứng dụng phức tạp, cần cập nhật linh động).
>   - Quá trình phát triển: CP/Non-AUTOSAR đã phát triển từ rất lâu và ổn định, có một số chức năng còn là độc quyền, nên không có lý do gì để AP thay thế hoàn toàn các nền tảng khác được.
>   - Chia sẻ tài nguyên phần cứng: CP sử dụng cho các ECU nhúng truyền thống (chỉ cần xử lý dữ liệu cảm biến), AP sử dụng cho các ECU kiến trúc mới mạnh mẽ và nhiều core. Điều này giúp tối ưu chi phí và hiệu suất.

## 2. Kiến trúc AP

Chương này sẽ giải thích AP dưới góc nhìn logic (logical view) và góc nhìn vật lý (physical view).
Để hiểu logical view và physical view là gì, tham khảo [4+1 View Model](https://en.wikipedia.org/wiki/4%2B1_architectural_view_model).

### 2.1. Logical view

Hình dưới là kiến trúc của AP release R22-11. Lưu ý, những bản release mới hơn, kiến trúc có thể thay đổi. Bạn có thể xem lịch sử release của AUTOSAR [tại đây](https://www.autosar.org/about/history).

![light mode only][img_2]{: width="800" height="420" .light }
![dark mode only][img_2d]{: width="800" height="420" .dark }

| Viết tắt       | Thuật ngữ, từ ngữ gốc                                                                       | Ý nghĩa                                                                                                                                                                                                                                                                                                                                                      |
| -------------- | ------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| AA             | Adaptive Applications                                                                       | Nằm trên cùng của kiến trúc, là các ứng dụng được phát triển, khởi chạy dựa trên AP                                                                                                                                                                                                                                                                          |
| ARA, ara       | AUTOSAR Runtime for Adaptive applications                                                   | Đề cập tới một bộ các APIs được tiêu chuẩn hóa mà AP cung cấp để phát triển AA.                                                                                                                                                                                                                                                                              |
| FCs, FC        | Functional Cluster(s)                                                                       | Là các ứng dụng cơ bản để tạo   nên AP.<br>     Service Functional Cluster cung cấp các service có sẵn cho AA sử   dụng.<br>     Foundation Functional Cluster cung cấp chức năng hoàn thiện cho AP.                                                                                                                                                         |
| Non-PF Service | Non-Platform Service                                                                        | Là service mà không phải do AP cung cấp.                                                                                                                                                                                                                                                                                                                     |
| POSIX-PSE51    | Portable Operating System   Interface<br>     PSE51 is the minimum real-time system profile | POSIX là một nhóm các tiêu chuẩn làm tăng tính tương thích giữa các hệ điều hành.<br> Phần mềm sử dụng, tuân thủ tiêu chuẩn POSIX có thể dễ dàng chuyển đổi và chạy trên các hệ điều hành giống UNIX (Linux, MacOS).<br> Và POSIX-PSE51 là một tập hợp con của POSIX được thiết kế riêng cho các hệ thống nhúng thời gian thực với tài nguyên tiết kiệm hơn. |
| C++ STL        | C++ Standard Template Library                                                               | Thư viện tiêu chuẩn C++                                                                                                                                                                                                                                                                                                                                      |

Việc khởi chạy các AA được quản lý bởi 1 FC tên là Execution Management (EM - ara::exec). Thật ra, các FC khác cũng được coi là những ứng dụng và cũng được EM quản lý khởi chạy theo cùng cách thức khởi chạy AA, chỉ riêng bản thân EM là có cách khởi chạy khác biệt. Nhưng lưu ý rằng, EM không quyết định AA bắt đầu và kết thúc khi nào, mà là do FC tên State Management (SM - ara::sm) chỉ huy EM kiểm soát khởi chạy các ứng dụng.

FC tên Communication Management (CM - ara::com) sẽ cung cấp các chức năng giao tiếp hướng dịch vụ, để các AA có thể tương tác với nhau trong cùng một ECU hoặc giữa các ECU. AA và FCs có thể sử dụng bất kỳ Non-PF service nào cũng được, miễn là chúng không gây xung đội với các chức năng AP và tuân thủ các yêu cầu về an toàn, bảo mật của dự án.

### 2.2. Physical view

#### 2.2.1. OS, processes và threads

#### 2.2.2. Triển khai FCs dựa trên thư viện (library-based) hay dịch vụ (service-based)

#### 2.2.3. Sự tương tác (giao tiếp) giữa FCs

#### 2.2.4. Machine/hardware

## 3. Tài liệu tham khảo

- [1] AUTOSAR. (2022). *Explanation of Adaptive Platform Design*, R22-11 [Online]. Available: [link](https://www.autosar.org/fileadmin/standards/R22-11/AP/AUTOSAR_EXP_PlatformDesign.pdf).

[//]: # (----------SCOPE OF DECLARATION OF LIST OF IMAGES USED IN POST----------)
[img_1]: /assets/img/2024-11-overview-of-AP/01_exemplary_deployment_of_different_platforms.png "Ví dụ về hệ thống tích hợp của nhiều nền tảng"
[img_1d]: /assets/img/2024-11-overview-of-AP/01d_exemplary_deployment_of_different_platforms.png "Ví dụ về hệ thống tích hợp của nhiều nền tảng"
[img_2]: /assets/img/2024-11-overview-of-AP/02_AP_architecture_logical_view.png "Kiến trúc AP dưới góc nhìn logic R22-11"
[img_2d]: /assets/img/2024-11-overview-of-AP/02d_AP_architecture_logical_view.png "Kiến trúc AP dưới góc nhìn logic R22-11"
