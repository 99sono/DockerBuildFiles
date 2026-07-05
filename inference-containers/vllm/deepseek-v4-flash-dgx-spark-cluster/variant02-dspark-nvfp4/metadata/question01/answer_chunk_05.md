# Part (c) — Constructing P and D for diagonalization

We place the eigenvectors as columns of $P$ and eigenvalues on the diagonal of $D$ in the same order.

Ordering: $\lambda_1 = 2 - \sqrt{2}$, $\lambda_2 = 2$, $\lambda_3 = 2 + \sqrt{2}$

$$
P = \begin{pmatrix}
1 & -1 & 1 \\
\sqrt{2} & 0 & -\sqrt{2} \\
1 & 1 & 1
\end{pmatrix},
\qquad
D = \begin{pmatrix}
2 - \sqrt{2} & 0 & 0 \\
0 & 2 & 0 \\
0 & 0 & 2 + \sqrt{2}
\end{pmatrix}
$$

Then $A = P D P^{-1}$.

Verification with SymPy:

```python
P = sp.Matrix([[1, -1, 1], [sp.sqrt(2), 0, -sp.sqrt(2)], [1, 1, 1]])
D = sp.diag(2 - sp.sqrt(2), 2, 2 + sp.sqrt(2))
sp.simplify(P * D * P.inv()) == A
# True
```

[Continue to chunk 06 →]
