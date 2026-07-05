# Final Summary — All Results

## Matrix

$$
A = \begin{pmatrix} 2 & -1 & 0 \\ -1 & 2 & -1 \\ 0 & -1 & 2 \end{pmatrix}
$$

## Part (a) — Eigenvalues

$$
\lambda_1 = 2 - \sqrt{2} \approx 0.5858, \quad
\lambda_2 = 2, \quad
\lambda_3 = 2 + \sqrt{2} \approx 3.4142
$$

## Part (b) — Eigenvectors

$$
v_1 = \begin{pmatrix} 1 \\ \sqrt{2} \\ 1 \end{pmatrix}, \quad
v_2 = \begin{pmatrix} -1 \\ 0 \\ 1 \end{pmatrix}, \quad
v_3 = \begin{pmatrix} 1 \\ -\sqrt{2} \\ 1 \end{pmatrix}
$$

## Part (c) — Diagonalization

$$
P = \begin{pmatrix}
1 & -1 & 1 \\
\sqrt{2} & 0 & -\sqrt{2} \\
1 & 1 & 1
\end{pmatrix},
\quad
D = \begin{pmatrix}
2-\sqrt{2} & 0 & 0 \\
0 & 2 & 0 \\
0 & 0 & 2+\sqrt{2}
\end{pmatrix},
\quad
A = P D P^{-1}
$$

## Part (d) — $A^{10}$

$$
A^{10} = \begin{pmatrix}
54320 & -76096 & 53296 \\
-76096 & 107616 & -76096 \\
53296 & -76096 & 54320
\end{pmatrix}
$$

## Bonus — General $n \times n$ case

$$
\lambda_k = 2 - 2\cos\left(\frac{k\pi}{n+1}\right) = 4\sin^2\left(\frac{k\pi}{2(n+1)}\right), \quad k = 1, 2, \ldots, n
$$

The eigenvectors are discrete sine waves:

$$
v^{(k)}_j = \sin\left(\frac{jk\pi}{n+1}\right), \quad j = 1, 2, \ldots, n
$$
