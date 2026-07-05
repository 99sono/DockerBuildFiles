# Part (d) — Computing $A^{10}$ using diagonalization

Using $A = P D P^{-1}$, we have $A^{10} = P D^{10} P^{-1}$.

Since $D$ is diagonal, $D^{10}$ is simply each diagonal entry raised to the 10th power:

$$
D^{10} = \begin{pmatrix}
(2 - \sqrt{2})^{10} & 0 & 0 \\
0 & 2^{10} & 0 \\
0 & 0 & (2 + \sqrt{2})^{10}
\end{pmatrix}
$$

Where $2^{10} = 1024$.

Now compute $A^{10} = P D^{10} P^{-1}$:

$$
P = \begin{pmatrix}
1 & -1 & 1 \\
\sqrt{2} & 0 & -\sqrt{2} \\
1 & 1 & 1
\end{pmatrix},
\qquad
P^{-1} = \begin{pmatrix}
\frac{1}{4} & \frac{\sqrt{2}}{4} & \frac{1}{4} \\
-\frac{1}{2} & 0 & \frac{1}{2} \\
\frac{1}{4} & -\frac{\sqrt{2}}{4} & \frac{1}{4}
\end{pmatrix}
$$

Let $a = (2 - \sqrt{2})^{10}$ and $b = (2 + \sqrt{2})^{10}$.

Then:

$$
A^{10} = \frac{1}{4}\begin{pmatrix}
a + 4\cdot1024 + b & \sqrt{2}(b - a) & -4\cdot1024 + a + b \\
\sqrt{2}(b - a) & 2(a + b) & \sqrt{2}(b - a) \\
-4\cdot1024 + a + b & \sqrt{2}(b - a) & a + 4\cdot1024 + b
\end{pmatrix}
$$

Let's compute $a$ and $b$ numerically:

- $a = (2 - \sqrt{2})^{10} \approx (0.585786)^{10} \approx 0.00494$
- $b = (2 + \sqrt{2})^{10} \approx (3.414214)^{10} \approx 196008.99506$

So $a$ is negligible and $b$ dominates.

[Continue to chunk 08 →]
