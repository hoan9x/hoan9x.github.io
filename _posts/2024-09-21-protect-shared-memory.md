---
title: Protect shared memory
description: The issue of shared data in multithreading
author: hoan9x
date: 2024-09-21 11:30:00 +0700
categories: [Cpp, Multi-Threading]
---

+ The following program has `count` as data shared between 2 threads.<br>
+ Both threads increment the variable `count` to equal the number `ITERATIONS`.<br>
+ The goal is that after the 2 threads finish, the variable `count` should be equal to `ITERATIONS*2`.

```cpp
#include <iostream>
#include <thread>
#include <atomic>

int main()
{
    int count{0};
    // std::atomic<int> count{0};
    /* The larger the ITERATIONS number, the higher the error rate */
    const long ITERATIONS{100'000'000};
    std::thread t1([&count](){
        for(int i = 0; i < ITERATIONS; i++) ++count;
    });
    std::thread t2([&count](){
        for(int i = 0; i < ITERATIONS; i++) ++count;
    });
    t1.join();
    t2.join();

    std::cout << std::to_string(count) << std::endl;
    if (ITERATIONS*2==count)
    {
        std::cout << "TRUE" << std::endl;
    }
    else
    {
        std::cout << "FALSE" << std::endl;
    }
    return 0;
}
```

+ Issues: The result of `count` after running the program is always **less than or equal** to `ITERATIONS*2`.<br>
+ This is contrary to the expectation that `count` must always be equal to `ITERATIONS*2`.<br>
+ Explain the issue: To execute the `++count` line, the CPU must go through at least the following steps:
    - (1) Get the `count` value and store it in the register;
    - (2) perform calculations;
    - (3) save the `count` value after calculation.
+ So `++count` has to go through many steps, and these steps will interfere with each other in 2 threads. There will be a case where `count` in both threads performs step (1), then step (2), (3), so 2 iterations occur, but `count` only increases by 1.

> To solve the issue explained above, we can declare the `count` as `std::atomic<int>` variable, or use `std::mutex` to protect the execution area of ​​`++count`.
{: .prompt-tip }
