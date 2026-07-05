# Part (a) — Solving for eigenvalues

From chunk 01, the characteristic polynomial is:

$$
\det(A - \lambda I) = (\lambda - 2)(\lambda^2 - 4\lambda + 2) = 0
$$

Setting each factor to zero:

**Factor 1:** $\lambda - 2 = 0 \implies \lambda_2 = 2$

**Factor 2:** $\lambda^2 - 4\lambda + 2 = 0$

Using the quadratic formula:

$$
\lambda = \frac{4 \pm \sqrt{16 - 8}}{2} = \frac{4 \pm \sqrt{8}}{2} = \frac{4 \pm 2\sqrt{2}}{2} = 2 \pm \sqrt{2}
$$

So the three eigenvalues are:

$$
\boxed{\lambda_1 = 2 - \sqrt{2}, \quad \lambda_2 = 2, \quad \lambda_3 = 2 + \sqrt{2}}
$$

In decimal form:

- $\lambda_1 \approx 0.5858$
- $\lambda_2 = 2.0000$
- $\lambda_3 \approx 3.4142$

Verification with SymPy:

```python
A.eigenvals()
# {2: 1, 2 - sqrt(2): 1, sqrt(2) + 2: 1}
```

Each eigenvalue has algebraic multiplicity 1.

[Continue to chunk 03 →]
