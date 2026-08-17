# Challenge 04: Code challenge — longest increasing subsequence

Write a complete, correct, and efficient Python solution for the classic
"Longest Increasing Subsequence" (LIS) problem, including the strict variant
and the non-decreasing variant.

Requirements:

1. Implement `lis_strict(nums)` that returns the LENGTH of the longest strictly
   increasing subsequence using an O(n log n) algorithm (binary search based).
2. Implement `lis_nondecreasing(nums)` for the non-decreasing variant, also
   O(n log n).
3. Implement `lis_path(nums)` that returns BOTH the length AND one actual
   subsequence achieving it (the sequence values, not just indices).
4. Include a `main()` that runs at least these test cases and asserts the
   results:

   - [10, 9, 2, 5, 3, 7, 101, 18]  → length 4
   - [0, 1, 0, 3, 2, 3]            → length 4
   - [7, 7, 7, 7]                  → strict length 1, non-decreasing length 4
   - []                            → length 0
   - [1, 2, 3, 4, 5]               → length 5
   - [5, 4, 3, 2, 1]               → length 1

5. Explain in comments how the binary-search LIS algorithm works and why it is
   O(n log n).

Write the complete, runnable script into `answer.md` as a single fenced python
code block.