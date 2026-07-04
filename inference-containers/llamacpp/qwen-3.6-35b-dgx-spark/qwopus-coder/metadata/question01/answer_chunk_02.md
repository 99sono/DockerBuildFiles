# Part (a): Characteristic Polynomial

We compute the characteristic polynomial:

$$\det(A - \lambda I) = \det\begin{bmatrix} 2-\lambda & -1 & 0 \\ -1 & 2-\lambda & -1 \\ 0 & -1 & 2-\lambda \end{bmatrix}$$

## Using cofactor expansion along the first row:

$$= (2-\lambda) \cdot \det\begin{bmatrix} 2-\lambda & -1 \\ -1 & 2-\lambda \end{bmatrix} + (-1) \cdot (-1) \cdot \det\begin{bmatrix} -1 & -1 \\ 0 & 2-\lambda \end{bmatrix}$$

$$= (2-\lambda)\left[(2-\lambda)^2 - 1\right] + 1 \cdot \left[-(2-\lambda)\right]$$

$$= (2-\lambda)\left[(2-\lambda)^2 - 1 - 1\right]$$

$$= (2-\lambda)\left[(2-\lambda)^2 - 2\right]$$

## Expanding:

Let $u = 2 - \lambda$. Then:

$$(2-\lambda)(\lambda^2 - 4\lambda + 2) = -\lambda^3 + 6\lambda^2 - 10\lambda + 4$$

**Characteristic polynomial:** $\det(A - \lambda I) = (2-\lambda)(\lambda^2 - 4\lambda + 2)$

## Verification:

We can verify by expanding $(2-\lambda)(\lambda^2 - 4\lambda + 2)$:
- $= 2(\lambda^2 - 4\lambda + 2) - \lambda(\lambda^2 - 4\lambda + 2)$
- $= 2\lambda^2 - 8\lambda + 4 - \lambda^3 + 4\lambda^2 - 2\lambda$
- $= -\lambda^3 + 6\lambda^2 - 10\lambda + 4$ ✓

This matches the sympy computation: `-(λ - 2)(λ² - 4λ + 2)`
