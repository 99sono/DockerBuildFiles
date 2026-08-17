

```python
#!/usr/bin/env python3
"""
Longest Increasing Subsequence (LIS) — strict and non-decreasing variants.

Binary-search LIS algorithm:
-----------------------------
Maintain a list `tails` where:

    tails[k] = the smallest possible ending value of an increasing
               subsequence of length k + 1 seen so far.

`tails` is always sorted, so we can binary search it.

For each new value x:

* Strictly increasing variant:
    Use bisect_left(tails, x).
    This finds the first position where tails[pos] >= x.
    Therefore x can extend a subsequence of length `pos` to length `pos + 1`.
    If pos == len(tails), x creates a new longest length.
    Otherwise, replace tails[pos] with x to keep the minimal possible tail.

* Non-decreasing variant:
    Use bisect_right(tails, x).
    This finds the first position where tails[pos] > x.
    Therefore x can extend a subsequence of length `pos` to length `pos + 1`,
    while still allowing equal values.

Why O(n log n)?
---------------
For each of the n elements, we perform one binary search in `tails`,
whose length is at most n. Binary search costs O(log n), and all other
per-element work is O(1). Thus the total time is O(n log n).
"""

from bisect import bisect_left, bisect_right


def _lis_length(nums, strict=True):
    """
    Return only the length of the LIS.

    Args:
        nums: Sequence of comparable values.
        strict: If True, require strictly increasing values.
                If False, allow non-decreasing values.

    Returns:
        Length of the longest increasing / non-decreasing subsequence.
    """
    tails = []

    for x in nums:
        if strict:
            # First index where tails[pos] >= x.
            pos = bisect_left(tails, x)
        else:
            # First index where tails[pos] > x.
            pos = bisect_right(tails, x)

        if pos == len(tails):
            # x extends the longest subsequence seen so far.
            tails.append(x)
        else:
            # x is a better, smaller tail for a subsequence of length pos + 1.
            tails[pos] = x

    return len(tails)


def lis_strict(nums):
    """
    Return the length of the longest strictly increasing subsequence.

    Example:
        lis_strict([10, 9, 2, 5, 3, 7, 101, 18]) == 4
    """
    return _lis_length(nums, strict=True)


def lis_nondecreasing(nums):
    """
    Return the length of the longest non-decreasing subsequence.

    Example:
        lis_nondecreasing([7, 7, 7, 7]) == 4
    """
    return _lis_length(nums, strict=False)


def lis_path(nums, strict=True):
    """
    Return both the length and one actual subsequence achieving that length.

    Args:
        nums: Sequence of comparable values.
        strict: If True, return a strictly increasing subsequence.
                If False, return a non-decreasing subsequence.

    Returns:
        A tuple (length, sequence), where sequence contains values, not indices.

    Example:
        lis_path([10, 9, 2, 5, 3, 7, 101, 18])
        # => (4, [2, 3, 7, 18])  # one valid answer
    """
    # Materialize iterators so we can index into the input during reconstruction.
    if not isinstance(nums, (list, tuple)):
        nums = list(nums)

    # tails[k] is the current minimal tail value for length k + 1.
    tails = []

    # tail_index[k] is the index in nums of the element currently realizing tails[k].
    tail_index = []

    # prev[i] is the index of the predecessor of nums[i] in one valid LIS.
    prev = []

    for i, x in enumerate(nums):
        if strict:
            pos = bisect_left(tails, x)
        else:
            pos = bisect_right(tails, x)

        # If pos > 0, x extends a subsequence of length pos.
        # The predecessor is the current tail of that shorter length.
        prev.append(tail_index[pos - 1] if pos > 0 else -1)

        if pos == len(tails):
            # New longest length.
            tails.append(x)
            tail_index.append(i)
        else:
            # Improve the tail for length pos + 1.
            tails[pos] = x
            tail_index[pos] = i

    if not tails:
        return 0, []

    # Reconstruct one valid subsequence by following predecessor links
    # from the final tail of the longest length.
    result = []
    idx = tail_index[-1]
    while idx != -1:
        result.append(nums[idx])
        idx = prev[idx]

    result.reverse()
    return len(tails), result


def _is_subsequence(seq, nums):
    """
    Return True if seq appears in nums in the same order.

    This checks by value, which is sufficient to validate that the returned
    sequence is a valid subsequence of the input.
    """
    j = 0
    for x in nums:
        if j < len(seq) and x == seq[j]:
            j += 1
    return j == len(seq)


def _is_strictly_increasing(seq):
    """Return True if seq is strictly increasing."""
    return all(a < b for a, b in zip(seq, seq[1:]))


def _is_nondecreasing(seq):
    """Return True if seq is non-decreasing."""
    return all(a <= b for a, b in zip(seq, seq[1:]))


def main():
    """
    Run required test cases and assert correctness.
    """
    # Each case is:
    #   (input, expected strict LIS length, expected non-decreasing LIS length)
    test_cases = [
        ([10, 9, 2, 5, 3, 7, 101, 18], 4, 4),
        ([0, 1, 0, 3, 2, 3], 4, 4),
        ([7, 7, 7, 7], 1, 4),
        ([], 0, 0),
        ([1, 2, 3, 4, 5], 5, 5),
        ([5, 4, 3, 2, 1], 1, 1),
    ]

    for nums, expected_strict, expected_nondec in test_cases:
        # Check length-only functions.
        strict_len = lis_strict(nums)
        nondec_len = lis_nondecreasing(nums)

        assert strict_len == expected_strict, (
            f"strict length mismatch for {nums}: "
            f"got {strict_len}, expected {expected_strict}"
        )
        assert nondec_len == expected_nondec, (
            f"non-decreasing length mismatch for {nums}: "
            f"got {nondec_len}, expected {expected_nondec}"
        )

        # Check strict path reconstruction.
        length, seq = lis_path(nums, strict=True)
        assert length == expected_strict, (
            f"strict path length mismatch for {nums}: "
            f"got {length}, expected {expected_strict}"
        )
        assert len(seq) == length, (
            f"strict path sequence length mismatch for {nums}: "
            f"got {len(seq)}, expected {length}"
        )
        assert _is_subsequence(seq, nums), (
            f"strict path is not a subsequence for {nums}: {seq}"
        )
        assert _is_strictly_increasing(seq), (
            f"strict path is not strictly increasing for {nums}: {seq}"
        )

        # Check non-decreasing path reconstruction.
        length, seq = lis_path(nums, strict=False)
        assert length == expected_nondec, (
            f"non-decreasing path length mismatch for {nums}: "
            f"got {length}, expected {expected_nondec}"
        )
        assert len(seq) == length, (
            f"non-decreasing path sequence length mismatch for {nums}: "
            f"got {len(seq)}, expected {length}"
        )
        assert _is_subsequence(seq, nums), (
            f"non-decreasing path is not a subsequence for {nums}: {seq}"
        )
        assert _is_nondecreasing(seq), (
            f"non-decreasing path is not non-decreasing for {nums}: {seq}"
        )

    print("All LIS tests passed.")


if __name__ == "__main__":
    main()
```