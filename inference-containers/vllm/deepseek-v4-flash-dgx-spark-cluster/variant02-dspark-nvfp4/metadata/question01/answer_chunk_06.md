# Verification: $A = P D P^{-1}$

Let's compute $P^{-1}$ explicitly and verify the product.

First, compute $P^{-1}$:

For $P = \begin{pmatrix} 1 & -1 & 1 \\ \sqrt{2} & 0 & -\sqrt{2} \\ 1 & 1 & 1 \end{pmatrix}$:

We can find $P^{-1}$ using row reduction or the adjugate formula. Using SymPy:

```python
P.inv()
```

Result:

$$
P^{-1} = \begin{pmatrix}
\frac{1}{4} & \frac{\sqrt{2}}{4} & \frac{1}{4} \\[4pt]
-\frac{1}{2} & 0 & \frac{1}{2} \\[4pt]
\frac{1}{4} & -\frac{\sqrt{2}}{4} & \frac{1}{4}
\end{pmatrix}
$$

Now verify $A = P D P^{-1}$:

```python
import sympy as sp
A = sp.Matrix([[2, -1, 0], [-1, 2, -1], [0, -1, 2]])
P = sp.Matrix([[1, -1, 1], [sp.sqrt(2), 0, -sp.sqrt(2)], [1, 1, 1]])
D = sp.diag(2 - sp.sqrt(2), 2, 2 + sp.sqrt(2))

sp.simplify(P * D * P.inv())
# ⎡2  -1  0 ⎤
# ⎢-1  2  -1⎥
# ⎣0  -1  2 ⎦
```

$$
P D P^{-1} = \begin{pmatrix} 2 & -1 & 0 \\ -1 & 2 & -1 \\ 0 & -1 & 2 \end{pmatrix} = A \quad \checkmark
$$

Diagonalization is confirmed.

[Continue to chunk 07 →]
