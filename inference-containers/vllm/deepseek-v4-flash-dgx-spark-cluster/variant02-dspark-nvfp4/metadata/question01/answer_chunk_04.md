# Part (b) — Verification of eigenvectors

Let's verify all three eigenvectors with SymPy:

```python
A.eigenvects()
# [
#   (2 - sqrt(2), 1, [Matrix([[1], [sqrt(2)], [1]])]),
#   (2,          1, [Matrix([[-1], [0],     [1]])]),
#   (2 + sqrt(2), 1, [Matrix([[1], [-sqrt(2)], [1]])])
# ]
```

Check each one manually:

**For $\lambda = 2 - \sqrt{2}$:**
$$
A \cdot \begin{pmatrix}1 \\ \sqrt{2} \\ 1\end{pmatrix}
= \begin{pmatrix}2 - \sqrt{2} \\ 2\sqrt{2} - 2 \\ 2 - \sqrt{2}\end{pmatrix}
= (2-\sqrt{2})\begin{pmatrix}1 \\ \sqrt{2} \\ 1\end{pmatrix}
\ \checkmark
$$

**For $\lambda = 2$:**
$$
A \cdot \begin{pmatrix}-1 \\ 0 \\ 1\end{pmatrix}
= \begin{pmatrix}-2 \\ 2 \\ -2\end{pmatrix}
= 2\begin{pmatrix}-1 \\ 0 \\ 1\end{pmatrix}
\ \checkmark
$$

**For $\lambda = 2 + \sqrt{2}$:**
$$
A \cdot \begin{pmatrix}1 \\ -\sqrt{2} \\ 1\end{pmatrix}
= \begin{pmatrix}2 + \sqrt{2} \\ -2\sqrt{2} - 2 \\ 2 + \sqrt{2}\end{pmatrix}
= (2+\sqrt{2})\begin{pmatrix}1 \\ -\sqrt{2} \\ 1\end{pmatrix}
\ \checkmark
$$

All three eigenvectors form a basis of $\mathbb{R}^3$ (they are linearly independent since each corresponds to a distinct eigenvalue).

[Continue to chunk 05 →]
