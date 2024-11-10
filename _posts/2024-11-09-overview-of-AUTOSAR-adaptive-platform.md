---
title: Tổng quan về AUTOSAR adaptive platform
description: Tổng quan về AP và các khái niệm chính
author: hoan9x
date: 2024-11-09 20:00:00 +0700
categories: [Automotive, AUTOSAR AP]
---

## 1. Phạm vi kỹ thuật và cách tiếp cận

### 1.1. Bối cảnh ra đời một ECU thông minh

Phần mềm trong các ECU nhúng truyền thống thường được thiết kế và triển khai cho xe mà không cần cập nhật gì đáng kể trong suốt vòng đời của chúng. Các phần mềm này thường kiểm soát tín hiệu đầu ra dựa trên tín hiệu đầu vào (ví dụ: Airbag ECU) và thông tin từ các ECU có thể được kết nối với mạng lưới trong xe như CAN (Controller Area Network).

Hiện nay, xu hướng của xe tự hành (auto driving, driver assistance), nhu cầu giải trí khi lái xe (video playback, multimedia) và khả năng điều khiển mọi thứ từ xa (IoT, Wi-Fi, LTE, GPS) khiến lập trình phần mềm cho xe trở nên phức tạp. Các phần mềm này đòi hỏi nhiều tài nguyên tính toán, yêu cầu nghiêm ngặt về bảo mật cũng như tính toàn vẹn dữ liệu. Như vậy, phần mềm sẽ có nhu cầu cần được cập nhật trong suốt vòng đời của xe để cải thiện.

Tiêu chuẩn AUTOSAR classic platform (CP) giải quyết các nhu cầu cần cho ECU nhúng truyền thống rất tốt, nhưng không thể đáp ứng được với xu hướng hiện tại. Do đó, AUTOSAR adaptive platform (AP) ra đời. AP cung cấp các cơ chế truyền thông và tính toán hiệu suất cao, cũng như khả năng cấu hình, cập nhật phần mềm một cách linh hoạt.

### 1.2. Công nghệ thúc đẩy nền tảng mới

Ethernet (mạng máy tính) và Processor (bộ xử lý) là hai nhóm công nghệ chính đằng sau của AP. Như đã trình bày ở trên, xu hướng của xe tự hành, nhu cầu giải trí... làm cho băng thông mạng được sử dụng nhiều hơn. Chuẩn giao tiếp CAN không còn phù hợp nữa, thành ra giao tiếp Ethernet lại là lựa chọn hàng đầu. CP mặc dù cũng hỗ trợ Ethernet, nhưng chủ yếu chỉ được thiết kết tối ưu với các chuẩn giao tiếp cũ, khó tận dụng và hưởng lợi đầy đủ từ khả năng giao tiếp dựa trên chuẩn Ethernet mới hơn.

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
>   - Chia sẻ tài nguyên phần cứng: CP sử dụng cho các ECU nhúng truyền thống (chỉ cần xử lý dữ liệu cảm biến), AP sử dụng cho các ECU kiến trúc mới mạnh mẽ và nhiều core. Điều này giúp tối giữa ưu chi phí và hiệu suất.

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
| FCs, FC        | Functional Cluster(s)                                                                       | Là các ứng dụng cơ bản để tạo   nên AP.<br>     Platform Service FCs cung cấp các service có sẵn cho AA sử   dụng.<br>     Platform Foundation FCs cung cấp chức năng hoàn thiện cho AP.                                                                                                                                                                     |
| Non-PF Service | Non-Platform Service                                                                        | Là service mà không phải do AP cung cấp.                                                                                                                                                                                                                                                                                                                     |
| POSIX-PSE51    | Portable Operating System   Interface<br>     PSE51 is the minimum real-time system profile | POSIX là một nhóm các tiêu chuẩn làm tăng tính tương thích giữa các hệ điều hành.<br> Phần mềm sử dụng, tuân thủ tiêu chuẩn POSIX có thể dễ dàng chuyển đổi và chạy trên các hệ điều hành giống UNIX (Linux, MacOS).<br> Và POSIX-PSE51 là một tập hợp con của POSIX được thiết kế riêng cho các hệ thống nhúng thời gian thực với tài nguyên tiết kiệm hơn. |
| C++ STL        | C++ Standard Template Library                                                               | Thư viện tiêu chuẩn C++                                                                                                                                                                                                                                                                                                                                      |

Việc khởi chạy các AA được quản lý bởi 1 FC tên là Execution Management (EM - ara::exec). Thật ra, các FC khác cũng được coi là những ứng dụng và cũng được EM quản lý khởi chạy theo cùng cách thức khởi chạy AA, chỉ riêng bản thân EM là có cách khởi chạy khác biệt. Nhưng lưu ý rằng, EM không quyết định AA bắt đầu và kết thúc khi nào, mà là do FC tên State Management (SM - ara::sm) chỉ huy EM kiểm soát khởi chạy các ứng dụng.

FC tên Communication Management (CM - ara::com) sẽ cung cấp các chức năng giao tiếp hướng dịch vụ, để các AA có thể tương tác với nhau trong cùng một ECU hoặc giữa các ECU. AA và FCs có thể sử dụng bất kỳ Non-PF service nào cũng được, miễn là chúng không gây xung đội với các chức năng AP và tuân thủ các yêu cầu về an toàn, bảo mật của dự án.

### 2.2. Physical view

#### 2.2.1. OS, processes và threads

- Hệ điều hành (OS - Operating System) của AP yêu cầu khả năng xử lý đa tiến trình theo tiêu chuẩn POSIX.
- Mỗi AA là một tiến trình độc lập, với không gian bộ nhớ và namespace riêng.
- Một AA có thể chứa nhiều tiến trình, triển khai trên một hoặc nhiều AP instances.
- FCs cũng có thể được triển khai dưới dạng tiến trình.
- Tất cả các tiến trình này có thể là một tiến trình đơn luồng hoặc đa luồng.
- AA chạy trên ARA nên chỉ sử dụng được PSE51 APIs, còn FCs tự do sử dụng mọi interface của OS.

Tóm lại, từ quan điểm của OS, AP và AA chỉ là một tập hợp các tiến trình, mỗi tiến trình chứa một hoặc nhiều luồng, không có sự khác biệt giữa các tiến trình này. Các tiến trình này tương tác với nhau thông qua IPC, nhưng AA tốt nhất là không sử dụng IPC trực tiếp mà chỉ nên giao tiếp thông qua ARA.

#### 2.2.2. Triển khai FCs dựa trên thư viện (library-based) hay dịch vụ (service-based)

Như đã giải thích ở trên, các FCs có thể là module của Platform Service FCs hoặc Platform Foundation FCs. Và thật ra, chúng đều chỉ là các tiến trình (process), nên để AA cũng là tiến trình tương tác với các FCs cũng là tiến trình, chúng cần dùng IPC (Inter Process Communication - giao tiếp giữa các tiến trình). Có hai cách thiết kế để triển khai FCs thực hiện điều này:
- Cách thứ nhất là thiết kế "Library-based": FCs phải cung cấp một library interface, và AA sử dụng trực tiếp library interface này để gọi IPC. Có thể hiểu đơn giản là AA sẽ include một thư viện do FCs của AP cung cấp và gọi các APIs để IPC.
- Cách thứ hai là thiết kế "Service-based": Thay vì AA và FCs kết nối trực tiếp bằng library interface, một hệ thống quản lý giao tiếp trung gian gọi là Communication Management bao gồm proxy library (thư viện trung gian) được thêm vào.
  + Proxy library: Là một thư viện được AA sử dụng, nó đóng vai trò như một "cầu nối" để liên kết đến Server, nhưng không giao tiếp trực tiếp với Server mà gọi các hàm trong Communication Management.
  + Communication Management: Một hệ thống sẽ nhận yêu cầu từ proxy library trong AA, sau đó điều phối quá trình giao tiếp với tiến trình của Server. Communication Management xử lý toàn bộ việc trao đổi dữ liệu và thông tin, đảm bảo rằng AA có thể giao tiếp với Server mà không cần biết cụ thể vị trí của Server.

Lưu ý rằng cách triển khai FCs có thể khác nhau, có thể AA chỉ giao tiếp với Communication Management hoặc kết hợp giao tiếp trực tiếp với Server qua proxy library.

Nguyên tắc chung khi chọn thiết kế cho FC là nếu nó chỉ dùng trên một AP instance, thiết kế "Library-based" sẽ hợp lý hơn vì đơn giản và hiệu quả. Nhưng nếu dùng theo kiểu phân tán (có nhiều AP instance), thì thiết kế "Service-based" là tốt hơn, vì Communication Management giúp giao tiếp mượt mà cho dù bất kể AA và Service ở đâu. Các FCs trong Platform Foundation FCs thường là "Library-based", còn Platform Service FCs thì là "Service-based" như tên gọi của chúng đã gợi ý.

Cuối cùng, cũng có thể không triển khai FC thành các tiến trình riêng mà chỉ là một thư viện chạy trong tiến trình của AA, miễn là nó đáp ứng đủ các yêu cầu kỹ thuật mà AP đưa ra. Trong trường hợp này, AA và FCs sẽ tương tác qua các cuộc gọi hàm bình thường thay vì qua IPC như đã nói.

#### 2.2.3. Sự tương tác (giao tiếp) giữa FCs

Các FCs có thể giao tiếp với nhau theo cách riêng biệt tùy vào mỗi triển khai AP khác nhau, nó không bị ràng buộc bởi các giới hạn của ARA. Ngoài ra, trong bản AP18-03, một khái niệm mới gọi là giao diện Inter-Functional-Cluster (IFC) đã được giới thiệu. Đây là giao diện mà các FC cung cấp cho nhau để giao tiếp. Nhưng lưu ý rằng, giao diện này không phải là một phần của ARA và không phải là yêu cầu chính thức trong các triển khai AP. Tuy nhiên, giao diện này giúp phát triển đặc tả AP dễ dàng hơn bằng cách làm rõ cách các FC tương tác, đồng thời giúp người sử dụng có cái nhìn rõ ràng hơn về kiến trúc của AP.

#### 2.2.4. Machine/hardware

AP coi phần cứng mà nó chạy trên đó là một *Machine*, và *Machine* ở đây có thể là một máy vật lý thật, một máy ảo hoàn toàn, một hệ điều hành ảo hóa bán phần (para-virtualized OS), một container ảo hóa cấp hệ điều hành (OS-level virtualized container), hoặc bất kỳ môi trường ảo hóa nào khác.

### 2.3. Methodology và manifest

Methodology đề cập đến việc chuẩn hóa quy trình phát triển AP, bao gồm work products (sản phẩm công việc) và các tác vụ cần thiết trong quá trình phát triển sản phẩm cho nền tảng thích ứng.

Hình dưới là bản tóm tắt quy trình làm việc (workflow) để triển khai AP:

![light mode only][img_3]{: width="962" height="715" .light }
![dark mode only][img_3d]{: width="962" height="715" .dark }
_Quy trình phát triển AP_

Manifest là tài liệu cấu hình hoặc các mô tả cho AP, thông thường thì các tệp ARXML (AUTOSAR XML) được coi là manifest, nhưng lưu ý chỉ tệp ARXML cho AUTOSAR AP mới là manifest, vì tệp ARXML cũng được sử dụng trong AUTOSAR CP. Các manifest này được chia thành các loại khác nhau như:

- Application Design: Mô tả các yếu tố thiết kế phần mềm ứng dụng cho AUTOSAR AP, bao gồm các loại dữ liệu, giao diện dịch vụ, lưu trữ dữ liệu bền vững, và các yêu cầu khác của ứng dụng. Nó giúp xác định cách thức triển khai ứng dụng trên AUTOSAR AP.
- Execution Manifest: Mô tả thông tin về cách thức triển khai ứng dụng trên AUTOSAR AP, bao gồm các chi tiết về mã thực thi và cách mã này được tích hợp vào machine. Nó đảm bảo rằng ứng dụng sẽ được triển khai đúng cách trên nền tảng.
- Service Instance Manifest: Mô tả cách giao tiếp dịch vụ được cấu hình cho ứng dụng như giao thức truyền thông. Nó xác định cách thức các dịch vụ sẽ được triển khai và truy cập từ ứng dụng, đặc biệt là các giao tiếp giữa các ứng dụng sử dụng giao thức dịch vụ nào.
- Machine Manifest: Mô tả cấu hình và các thông tin liên quan đến machine đang chạy AUTOSAR AP. Nó xác định phần mềm và cấu hình cần thiết để thiết lập một machine AUTOSAR AP.

Ví dụ về cấu hình ARXML:
```xml
<SERVICE-INTERFACE>
  <SHORT-NAME>radarInterface</SHORT-NAME>
  <EVENTS>
    <VARIABLE-DATA-PROTOTYPE>
      <SHORT-NAME>UpdateRate</SHORT-NAME>
      <TYPE-TREF DEST="STD-CPP-IMPLEMENTATION-DATA-TYPE">/AUTOSAR/StdTypes/uint32_t</TYPE-TREF>
    </VARIABLE-DATA-PROTOTYPE>
  </EVENTS>
</SERVICE-INTERFACE>
```
ARXML trên đang định nghĩa một service bao gồm `EVENTS` có tên là `UpdateRate` với kiểu dữ liệu là `uint32_t`, có thể coi tệp trên là sản phẩm **Service Interface Description** của quá trình **Define Services** trong **Quy trình phát triển AP** hình bên trên.

## 3. Tài liệu tham khảo

- [1] AUTOSAR. (2022). *Explanation of Adaptive Platform Design*, R22-11 [Online]. Available: [link](https://www.autosar.org/fileadmin/standards/R22-11/AP/AUTOSAR_EXP_PlatformDesign.pdf).

[//]: # (----------SCOPE OF DECLARATION OF LIST OF IMAGES USED IN POST----------)
[img_1]: /assets/img/2024-11-overview-of-AP/01_exemplary_deployment_of_different_platforms.png "Ví dụ về hệ thống tích hợp của nhiều nền tảng"
[img_1d]: /assets/img/2024-11-overview-of-AP/01d_exemplary_deployment_of_different_platforms.png "Ví dụ về hệ thống tích hợp của nhiều nền tảng"
[img_2]: /assets/img/2024-11-overview-of-AP/02_AP_architecture_logical_view.png "Kiến trúc AP dưới góc nhìn logic R22-11"
[img_2d]: /assets/img/2024-11-overview-of-AP/02d_AP_architecture_logical_view.png "Kiến trúc AP dưới góc nhìn logic R22-11"
[img_3]: /assets/img/2024-11-overview-of-AP/03_AP_development_workflow.png "Quy trình phát triển AP"
[img_3d]: /assets/img/2024-11-overview-of-AP/03d_AP_development_workflow.png "Quy trình phát triển AP"
