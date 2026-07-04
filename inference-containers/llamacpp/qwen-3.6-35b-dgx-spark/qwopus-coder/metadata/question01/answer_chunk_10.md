# Bonus: Interpretation as Discrete Laplacian

## Why this matrix appears:

The matrix $A$ is a **second-difference operator** (discrete 1D Laplacian) with an extra $+2I$ added. The pure discrete Laplacian would be:

$$L = \begin{bmatrix} 1 & -1 & 0 \\ -1 & 2 & -1 \\ 0 & -1 & 1 \end{bmatrix}$$

Our matrix is $A = L + I$. For an $n \times n$ version, the pure Laplacian would be:

$$L_n = \begin{bmatrix}
1 & -1 & 0 & \cdots & 0 \\
-1 & 2 & -1 & \cdots & 0 \\
0 & -1 & 2 & \cdots & 0 \\
\vdots & \vdots & \vdots & \ddots & -1 \\
0 & 0 & 0 & -1 & 1
\end{bmatrix}$$

And our $A = L + I$, so it has 2's on the diagonal instead of 1's at the corners.

## Eigenvalues of the pure Laplacian:

The eigenvalues of the $n \times n$ **free-endpoint** discrete Laplacian are well-known:

$$\mu_k = 2 - 2\cos\left(\frac{(k-1)\pi}{n}\right), \quad k = 1, 2, \ldots, n$$

But our matrix has a slightly different boundary condition — it has $+2$ in the corners rather than $+1$. This is actually the **Dirichlet-boundary** version of the discrete Laplacian (with zero boundary conditions outside the grid), which gives:

## Eigenvalues of our $A$:

$$\lambda_k = 2 + 2 - 2\cos\left(\frac{k\pi}{n+1}\right) = 4 - 2\cos\left(\frac{k\pi}{n+1}\right)$$

Wait — let me reconsider. The standard $n \times n$ tridiagonal Toeplitz matrix with diagonal $a$ and off-diagonal $b$ has eigenvalues:

$$\lambda_k = a + 2b\cos\left(\frac{k\pi}{n+1}\right), \quad k = 1, 2, \ldots, n$$

For our case, $a = 2$, $b = -1$, and $n = 3$:

$$\lambda_k = 2 + 2(-1)\cos\left(\frac{k\pi}{4}\right) = 2 - 2\cos\left(\frac{k\pi}{4}\right), \quad k = 1, 2, 3$$

Let's verify:
- $\lambda_1 = 2 - 2\cos(\pi/4) = 2 - \sqrt{2} \approx 0.5858$ ✓
- $\lambda_2 = 2 - 2\cos(2\pi/4) = 2 - 0 = 2$ ✓
- $\lambda_3 = 2 - 2\cos(3\pi/4) = 2 + \sqrt{2} \approx 3.4142$ ✓

## For general $n$:

The eigenvalues of the $n \times n$ matrix with 2 on the diagonal and −1 on the off-diagonals are:

$$\boxed{\lambda_k = 2 - 2\cos\left(\frac{k\pi}{n+1}\right), \quad k = 1, 2, \ldots, n}$$

The eigenvectors are:
$$v_{k,j} = \sin\left(\frac{kj\pi}{n+1}\right), \quad j = 1, 2, \ldots, n$$

This connects to the continuous eigenvalue problem for $-u''(x) = \lambda u(x)$ with $u(0) = u(1) = 0$:
- The continuous eigenvalues are $\lambda_k^{\text{cont}} = (k\pi)^2$
- The discrete approximation gives $\lambda_k^{\text{disc}} = 2 - 2\cos\left(\frac{k\pi}{n+1}\right) \approx \left(\frac{k\pi}{n+1}\right)^2$ for large $n$

This is a classic example of numerical discretization: the finite difference method for approximating the second derivative. The spacing between grid points is $\Delta x = \frac{1}{n+1}$, so multiplying by $\frac{1}{\Delta x^2} = (n+1)^2$ gives the approximation:

$$\lambda_k \approx \frac{(k\pi)^2}{(n+1)^2} \cdot \frac{(n+1)^2}{1} = (k\pi)^2 \quad \text{(scaled by } 1/\Delta x^2\text{)}$$

This shows why the discrete eigenvalues converge to $(k\pi)^2$ as $n \to \infty$ — they are approximations of the continuous Laplacian's spectrum.
