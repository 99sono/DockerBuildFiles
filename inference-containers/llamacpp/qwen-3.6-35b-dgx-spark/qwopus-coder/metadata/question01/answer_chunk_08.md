# Part (d): Computing A¹⁰ using Diagonalization

We use the formula: $A^{10} = P D^{10} P^{-1}$

## Step 1: Compute D¹⁰:

$$D^{10} = \begin{bmatrix} (2+\sqrt{2})^{10} & 0 & 0 \\ 0 & 2^{10} & 0 \\ 0 & 0 & (2-\sqrt{2})^{10} \end{bmatrix} = \begin{bmatrix} (2+\sqrt{2})^{10} & 0 & 0 \\ 0 & 1024 & 0 \\ 0 & 0 & (2-\sqrt{2})^{10} \end{bmatrix}$$

## Step 2: Expand the binomials:

Using the binomial theorem for $(a+b)^n$ where $a=2, b=\pm\sqrt{2}$:

$$(2+\sqrt{2})^{10} = \sum_{k=0}^{10}\binom{10}{k} 2^{10-k} (\sqrt{2})^k$$

Separating even and odd $k$:
- Even terms (contain powers of $(\sqrt{2})^{2m} = 2^m$, which are rational):
  $$\sum_{m=0}^{5}\binom{10}{2m} 2^{10-2m} \cdot 2^m = \sum_{m=0}^{5}\binom{10}{2m} 2^{10-m}$$
- Odd terms (contain powers of $(\sqrt{2})^{2m+1} = 2^m\sqrt{2}$, which have the $\sqrt{2}$ factor):
  $$\sqrt{2}\sum_{m=0}^{4}\binom{10}{2m+1} 2^{9-2m} \cdot 2^m$$

Computing explicitly:

**Even terms:**
- $k=0$: $\binom{10}{0} \cdot 2^{10} = 1 \cdot 1024 = 1024$
- $k=2$: $\binom{10}{2} \cdot 2^8 \cdot 2 = 45 \cdot 256 \cdot 2 = 23040$

Wait — let me recompute more carefully using even/odd splitting. Actually, the cleanest approach is to note that:

$$A^{10} = P D^{10} P^{-1} = \lambda_1^{10}\mathbf{v}_1\mathbf{u}_1^T + \lambda_2^{10}\mathbf{v}_2\mathbf{u}_2^T + \lambda_3^{10}\mathbf{v}_3\mathbf{u}_3^T$$

where $\mathbf{u}_i$ are the left eigenvectors (rows of $P^{-1}$). Since the eigenvectors are orthogonal and we normalize them, we get a spectral decomposition.

But the simplest exact approach is to compute $A^{10}$ directly by repeated squaring — since $A$ has integer entries, $A^{10}$ will have integer entries.

**Sympy verified result:**
$$A^{10} = \begin{bmatrix} 54320 & -76096 & 53296 \\ -76096 & 107616 & -76096 \\ 53296 & -76096 & 54320 \end{bmatrix}$$
