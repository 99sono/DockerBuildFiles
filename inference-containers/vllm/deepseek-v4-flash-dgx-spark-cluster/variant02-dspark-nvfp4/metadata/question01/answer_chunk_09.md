# Bonus — Eigenvalue pattern and generalization to $n \times n$

This matrix is the discrete 1D Laplacian (with Dirichlet boundary conditions):

$$
A_n = \begin{pmatrix}
2 & -1 & 0 & \cdots & 0 \\
-1 & 2 & -1 & \cdots & 0 \\
0 & -1 & 2 & \cdots & 0 \\
\vdots & \vdots & \vdots & \ddots & -1 \\
0 & 0 & 0 & -1 & 2
\end{pmatrix}_{n \times n}
$$

## Why these eigenvalues?

This matrix arises from the finite difference discretization of $-\frac{d^2 u}{dx^2}$ on $[0,1]$ with $u(0)=u(1)=0$. The eigenvectors are discrete sine waves:

For $k = 1, 2, \ldots, n$, the $k$-th eigenvector has components:

$$
v^{(k)}_j = \sin\left(\frac{jk\pi}{n+1}\right), \quad j = 1, 2, \ldots, n
$$

Applying $A_n$ to this vector:

$$
(A_n v^{(k)})_j = 2\sin\left(\frac{jk\pi}{n+1}\right) - \sin\left(\frac{(j-1)k\pi}{n+1}\right) - \sin\left(\frac{(j+1)k\pi}{n+1}\right)
$$

Using the identity $\sin(\alpha-\beta) + \sin(\alpha+\beta) = 2\sin\alpha\cos\beta$:

$$
= 2\sin\left(\frac{jk\pi}{n+1}\right) - 2\sin\left(\frac{jk\pi}{n+1}\right)\cos\left(\frac{k\pi}{n+1}\right)
$$

$$
= \left[2 - 2\cos\left(\frac{k\pi}{n+1}\right)\right] \sin\left(\frac{jk\pi}{n+1}\right)
$$

Therefore the $k$-th eigenvalue is:

$$
\boxed{\lambda_k = 2 - 2\cos\left(\frac{k\pi}{n+1}\right) = 4\sin^2\left(\frac{k\pi}{2(n+1)}\right)}, \quad k = 1, 2, \ldots, n
$$

## Check for $n = 3$

| $k$ | $\lambda_k = 2 - 2\cos\left(\frac{k\pi}{4}\right)$ | Matches? |
|-----|------------------------------------------------------|----------|
| 1 | $2 - 2\cos(\pi/4) = 2 - \sqrt{2}$ | $\checkmark$ |
| 2 | $2 - 2\cos(\pi/2) = 2 - 0 = 2$ | $\checkmark$ |
| 3 | $2 - 2\cos(3\pi/4) = 2 + \sqrt{2}$ | $\checkmark$ |

## General properties

- All eigenvalues are in $(0, 4)$ — the matrix is positive definite
- Eigenvalues are distinct for all $n$
- Smallest eigenvalue: $\lambda_1 = 2 - 2\cos\left(\frac{\pi}{n+1}\right) \approx \frac{\pi^2}{(n+1)^2}$ for large $n$
- Largest eigenvalue: $\lambda_n = 2 - 2\cos\left(\frac{n\pi}{n+1}\right) \to 4^-$ as $n \to \infty$
- The condition number $\kappa(A) = \frac{\lambda_n}{\lambda_1} \approx \frac{4(n+1)^2}{\pi^2}$, which grows as $O(n^2)$ — this is why iterative solvers struggle with large Laplacian matrices

[Continue to chunk 10 →]
