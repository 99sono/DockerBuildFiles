# Part (b) — Finding eigenvectors

For each eigenvalue $\lambda$, we solve $(A - \lambda I)v = 0$.

---

### Eigenvalue $\lambda = 2$

$$
(A - 2I) = \begin{pmatrix}
0 & -1 & 0 \\
-1 & 0 & -1 \\
0 & -1 & 0
\end{pmatrix}
$$

Row-reducing:

From row 1: $-v_2 = 0 \implies v_2 = 0$
From row 2: $-v_1 - v_3 = 0 \implies v_1 = -v_3$
From row 3: $-v_2 = 0$ (redundant)

So $v = (v_1, 0, -v_1)$. Choosing $v_1 = -1$ (to avoid fractions):

$$
v_{\lambda=2} = \begin{pmatrix} -1 \\ 0 \\ 1 \end{pmatrix}
$$

---

### Eigenvalue $\lambda = 2 - \sqrt{2}$

$$
(A - (2-\sqrt{2})I) = \begin{pmatrix}
\sqrt{2} & -1 & 0 \\
-1 & \sqrt{2} & -1 \\
0 & -1 & \sqrt{2}
\end{pmatrix}
$$

From row 1: $\sqrt{2}\,v_1 - v_2 = 0 \implies v_2 = \sqrt{2}\,v_1$
From row 3: $-v_2 + \sqrt{2}\,v_3 = 0 \implies -\sqrt{2}\,v_1 + \sqrt{2}\,v_3 = 0 \implies v_3 = v_1$

So:

$$
v_{\lambda=2-\sqrt{2}} = \begin{pmatrix} 1 \\ \sqrt{2} \\ 1 \end{pmatrix}
$$

---

### Eigenvalue $\lambda = 2 + \sqrt{2}$

$$
(A - (2+\sqrt{2})I) = \begin{pmatrix}
-\sqrt{2} & -1 & 0 \\
-1 & -\sqrt{2} & -1 \\
0 & -1 & -\sqrt{2}
\end{pmatrix}
$$

From row 1: $-\sqrt{2}\,v_1 - v_2 = 0 \implies v_2 = -\sqrt{2}\,v_1$
From row 3: $-v_2 - \sqrt{2}\,v_3 = 0 \implies \sqrt{2}\,v_1 - \sqrt{2}\,v_3 = 0 \implies v_3 = v_1$

So:

$$
v_{\lambda=2+\sqrt{2}} = \begin{pmatrix} 1 \\ -\sqrt{2} \\ 1 \end{pmatrix}
$$

[Continue to chunk 04 →]
