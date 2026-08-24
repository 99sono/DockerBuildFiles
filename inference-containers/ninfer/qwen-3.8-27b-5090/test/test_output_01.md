We first identify the pattern of \(f(n)\).

## 1. What does \(f(n)\) compute?

The recurrence is

\[
f(1)=1,
\]
\[
f(2n)=f(n),
\]
\[
f(2n+1)=f(2n)+1.
\]

Since \(f(2n)=f(n)\), the odd case can also be written as

\[
f(2n+1)=f(n)+1.
\]

Now think in binary:

- Multiplying by \(2\) appends a \(0\) in binary, so the number of \(1\)'s does not change.
- Computing \(2n+1\) appends a \(1\) in binary, so the number of \(1\)'s increases by \(1\).

Thus \(f(n)\) is exactly the number of \(1\)'s in the binary representation of \(n\). In other words,

\[
f(n)=\text{popcount}(n).
\]

For example:

\[
13 = 1101_2 \implies f(13)=3.
\]

Indeed,

\[
f(13)=f(12)+1=f(6)+1=f(3)+1=f(2)+2=1+2=3.
\]

So we need to count integers \(n\) with \(1 \le n \le 2048\) whose binary expansion contains exactly five \(1\)'s.

## 2. Count numbers from \(1\) to \(2048\) with exactly five \(1\)'s

We have

\[
2048 = 2^{11}.
\]

The integers

\[
0,1,2,\dots,2047
\]

are exactly all 11-bit binary strings, allowing leading zeros. For example,

\[
5 = 00000000101_2.
\]

To have exactly five \(1\)'s among 11 bit positions, we simply choose which 5 of the 11 positions contain a \(1\). Therefore the count is

\[
\binom{11}{5}.
\]

Now,

\[
\binom{11}{5}
=
\frac{11!}{5!6!}
=
\frac{11 \cdot 10 \cdot 9 \cdot 8 \cdot 7}{5 \cdot 4 \cdot 3 \cdot 2 \cdot 1}
=
462.
\]

We must check the endpoint \(2048\):

\[
2048 = 100000000000_2,
\]

which has only one \(1\), so it does not contribute to the count.

Also, \(0\) is not in the range \([1,2048]\), but \(0\) has zero \(1\)'s, so excluding it does not affect the count of numbers with exactly five \(1\)'s.

Thus the number of integers \(n\) in \([1,2048]\) with \(f(n)=5\) is

\[
\boxed{462}.
\]

## 3. Double-check

The 11 binomial coefficients

\[
\binom{11}{0},\binom{11}{1},\dots,\binom{11}{11}
\]

are

\[
1,\ 11,\ 55,\ 165,\ 330,\ 462,\ 462,\ 330,\ 165,\ 55,\ 11,\ 1.
\]

Their sum is

\[
2^{11}=2048,
\]

which matches the number of 11-bit strings from \(0\) to \(2047\). The coefficient for exactly five \(1\)'s is \(462\). Since \(2048\) itself has popcount \(1\), the final answer remains

\[
\boxed{462}.
\]