

```python
import bisect

# ---------------------------------------------------------------------------
# Binary-search LIS explanation
# ---------------------------------------------------------------------------
# For the strict variant we maintain a list `tails` such that:
#   tails[k] = smallest possible tail value of a strictly increasing
#              subsequence of length k + 1.
# `tails` is always strictly increasing, so it can be binary searched.
#
# For each element x:
#   pos = bisect_left(tails, x)
# If pos == len(tails), x can extend the longest subsequence found so far.
# Otherwise, x can replace tails[pos], the first tail >= x. This keeps the
# tail for that length as small as possible, which can only help future
# elements. The length of the LIS is len(tails) after all elements.
#
# For the non-decreasing variant, equal values are allowed to extend a
# subsequence, so we use bisect_right(tails, x): find the first tail > x.
#
# Each of the n elements performs one binary search in a list of length at
# most n, giving O(n log n) time. The path reconstruction below stores one
# parent index per element, so it is also O(n log n) time and O(n) space.
# ---------------------------------------------------------------------------


def lis_strict(nums):
    """Return the length of the longest strictly increasing subsequence."""
    tails = []
    for x in nums:
        pos = bisect.bisect_left(tails, x)
        if pos == len(tails):
            tails.append(x)
        else:
            tails[pos] = x
    return len(tails)


def lis_nondecreasing(nums):
    """Return the length of the longest non-decreasing subsequence."""
    tails = []
    for x in nums:
        pos = bisect.bisect_right(tails, x)
        if pos == len(tails):
            tails.append(x)
        else:
            tails[pos] = x
    return len(tails)


def lis_path(nums, strict=True):
    """
    Return (length, subsequence) for one longest subsequence.

    By default this is the strict increasing variant. If strict=False, it
    returns a non-decreasing subsequence.
    """
    tails = []
    tail_indices = []
    parent = []

    for i, x in enumerate(nums):
        if strict:
            pos = bisect.bisect_left(tails, x)
        else:
            pos = bisect.bisect_right(tails, x)

        if pos == len(tails):
            tails.append(x)
            tail_indices.append(i)
        else:
            tails[pos] = x
            tail_indices[pos] = i

        # The previous element in a subsequence ending at i is the current
        # tail of the shorter length, or -1 if this element starts a length-1
        # subsequence.
        parent.append(-1 if pos == 0 else tail_indices[pos - 1])

    length = len(tails)
    if length == 0:
        return 0, []

    # Walk backwards from the final tail.
    idx = tail_indices[-1]
    seq = []
    for _ in range(length):
        seq.append(nums[idx])
        idx = parent[idx]
    seq.reverse()
    return length, seq


def _assert_is_subsequence(seq, nums):
    """Raise AssertionError if seq is not a subsequence of nums."""
    it = iter(nums)
    for value in seq:
        for item in it:
            if item == value:
                break
        else:
            raise AssertionError(f"{seq} is not a subsequence of {nums}")


def main():
    # (nums, expected strict length, expected non-decreasing length)
    cases = [
        ([10, 9, 2, 5, 3, 7, 101, 18], 4, 4),
        ([0, 1, 0, 3, 2, 3], 4, 4),
        ([7, 7, 7, 7], 1, 4),
        ([], 0, 0),
        ([1, 2, 3, 4, 5], 5, 5),
        ([5, 4, 3, 2, 1], 1, 1),
    ]

    for nums, expected_strict, expected