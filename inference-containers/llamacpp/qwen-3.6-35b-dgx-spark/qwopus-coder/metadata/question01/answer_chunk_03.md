# Part (a): Solving for Eigenvalues

Setting the characteristic polynomial to zero:

$$(2 - \lambda)(\lambda^2 - 4\lambda + 2) = 0$$

## First eigenvalue:

From $2 - \lambda = 0$:

$$\boxed{\lambda_2 = 2}$$

## Other two eigenvalues (quadratic):

From $\lambda^2 - 4\lambda + 2 = 0$, apply the quadratic formula:

$$\lambda = \frac{4 \pm \sqrt{16 - 8}}{2} = \frac{4 \pm \sqrt{8}}{2} = \frac{4 \pm 2\sqrt{2}}{2} = 2 \pm \sqrt{2}$$

## All three eigenvalues:

$$\boxed{\lambda_1 = 2 + \sqrt{2} \approx 3.4142}$$
$$\boxed{\lambda_2 = 2}$$
$$\boxed{\lambda_3 = 2 - \sqrt{2} \approx 0.5858}$$

## Verification:

- Sum of eigenvalues = $(2 + \sqrt{2}) + 2 + (2 - \sqrt{2}) = 6$ = trace of $A = 2+2+2 = 6$ ✓
- Product of eigenvalues = $(2+\sqrt{2})(2)(2-\sqrt{2}) = 2(4-2) = 4$ = determinant of $A$ (can be checked) ✓

The eigenvalues are all **positive**, confirming that $A$ is positive definite — which makes sense since it's a discrete Laplacian plus 2 times the identity.
