# Part (a) — Setting up the characteristic equation

We are given:

$$
A = \begin{pmatrix}
2 & -1 & 0 \\
-1 & 2 & -1 \\
0 & -1 & 2
\end{pmatrix}
$$

The eigenvalues satisfy $\det(A - \lambda I) = 0$.

$$
A - \lambda I = \begin{pmatrix}
2-\lambda & -1 & 0 \\
-1 & 2-\lambda & -1 \\
0 & -1 & 2-\lambda
\end{pmatrix}
$$

The determinant of this tridiagonal matrix is:

$$
\det(A - \lambda I) = (2-\lambda) \cdot \det\begin{pmatrix}2-\lambda & -1 \\ -1 & 2-\lambda\end{pmatrix} - (-1) \cdot \det\begin{pmatrix}-1 & -1 \\ 0 & 2-\lambda\end{pmatrix} + 0
$$

Computing the minors:

$$
\det\begin{pmatrix}2-\lambda & -1 \\ -1 & 2-\lambda\end{pmatrix} = (2-\lambda)^2 - (-1)(-1) = (2-\lambda)^2 - 1
$$

$$
\det\begin{pmatrix}-1 & -1 \\ 0 & 2-\lambda\end{pmatrix} = (-1)(2-\lambda) - (-1)(0) = -(2-\lambda)
$$

So:

$$
\det(A - \lambda I) = (2-\lambda)\big[(2-\lambda)^2 - 1\big] + 1 \cdot \big[-(2-\lambda)\big]
$$

$$
= (2-\lambda)\big[(2-\lambda)^2 - 1 - 1\big]
$$

$$
= (2-\lambda)\big[(2-\lambda)^2 - 2\big]
$$

We can verify this with SymPy:

```python
import sympy as sp
lam = sp.symbols('lambda')
A = sp.Matrix([[2, -1, 0], [-1, 2, -1], [0, -1, 2]])
char_poly = A.charpoly(lam)
print(sp.factor(char_poly.as_expr()))
# Output: (λ - 2)*(λ^2 - 4*λ + 2)
```

This confirms our manual derivation. The characteristic polynomial factors as $(\lambda - 2)(\lambda^2 - 4\lambda + 2)$.

[Continue to chunk 02 →]
