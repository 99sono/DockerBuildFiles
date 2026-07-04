# Understanding the Problem

We are given the 3×3 symmetric matrix:

$$A = \begin{bmatrix} 2 & -1 & 0 \\ -1 & 2 & -1 \\ 0 & -1 & 2 \end{bmatrix}$$

This matrix has a very specific structure:
- It is **symmetric** ($A^T = A$), so all eigenvalues are guaranteed to be real.
- The diagonal entries are all 2, and the first super-diagonal and sub-diagonal are both −1.
- All other entries are zero.

## Initial Approach

This matrix is a classic **tridiagonal Toeplitz matrix** — it appears frequently in applications like:
- Discretization of the 1D Laplacian (second difference operator)
- The adjacency matrix plus identity of a path graph

### Plan:

1. **Part (a):** Compute $\det(A - \lambda I)$ to find the characteristic polynomial, then factor it to get eigenvalues.

2. **Part (b):** For each eigenvalue, solve $(A - \lambda_i I)\mathbf{v} = 0$ to find eigenvectors.

3. **Part (c):** Assemble $P$ (columns = eigenvectors) and $D$ (diagonal = eigenvalues), then verify $A = PDP^{-1}$.

4. **Part (d):** Use $A^n = PD^nP^{-1}$ to compute $A^{10}$.

5. **Bonus:** Connect to the theory of second-difference operators and the discrete Laplacian.

## Key Observation

Since $A$ is symmetric, its eigenvectors will be orthogonal — which makes checking our work easier. Also, this is a small matrix (3×3), so we can compute everything by hand with some algebraic care.
