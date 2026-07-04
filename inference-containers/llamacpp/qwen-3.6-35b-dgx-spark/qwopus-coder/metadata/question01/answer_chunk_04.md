# Part (b): Finding Eigenvectors for λ₁ = 2 + √2

We solve $(A - \lambda_1 I)\mathbf{v} = 0$ where $\lambda_1 = 2 + \sqrt{2}$:

$$A - (2+\sqrt{2})I = \begin{bmatrix} -\sqrt{2} & -1 & 0 \\ -1 & -\sqrt{2} & -1 \\ 0 & -1 & -\sqrt{2} \end{bmatrix}$$

## Row reduction:

Row 1: $-\sqrt{2}\,v_1 - v_2 = 0$ → $v_2 = -\sqrt{2}\,v_1$

Row 3: $-v_2 - \sqrt{2}\,v_3 = 0$ → $v_2 = -\sqrt{2}\,v_3$

From these two equations: $-\sqrt{2}\,v_1 = -\sqrt{2}\,v_3$ → $v_1 = v_3$

Row 2: $-v_1 - \sqrt{2}\,v_2 - v_3 = 0$ — verify consistency:
$$-v_1 - \sqrt{2}(-\sqrt{2}\,v_1) - v_1 = -v_1 + 2v_1 - v_1 = 0 \quad ✓$$

## Eigenvector:

Setting $v_1 = 1$, we get $v_3 = 1$ and $v_2 = -\sqrt{2}$.

$$\boxed{\mathbf{v}_1 = \begin{bmatrix} 1 \\ -\sqrt{2} \\ 1 \end{bmatrix}}$$

## Verification:

$$A\mathbf{v}_1 = \begin{bmatrix} 2 & -1 & 0 \\ -1 & 2 & -1 \\ 0 & -1 & 2 \end{bmatrix}\begin{bmatrix} 1 \\ -\sqrt{2} \\ 1 \end{bmatrix} = \begin{bmatrix} 2 + \sqrt{2} \\ -1 - 2\sqrt{2} - 1 \\ \sqrt{2} + 2 \end{bmatrix} = (2+\sqrt{2})\begin{bmatrix} 1 \\ -\sqrt{2} \\ 1 \end{bmatrix} = \lambda_1\mathbf{v}_1 \quad ✓$$
