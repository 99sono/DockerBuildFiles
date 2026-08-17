

```markdown
# Challenge 02: Solve these equations

## 1. Find all real solutions of:

\[
x^4 - 10x^3 + 35x^2 - 50x + 24 = 0
\]

We can rewrite the polynomial by grouping terms in a useful way.

Notice that

\[
x^4 - 10x^3 + 35x^2 - 50x + 24
\]

can be expressed using \(x^2 - 5x\). Let

\[
u = x^2 - 5x
\]

Then

\[
u^2 = x^4 - 10x^3 + 25x^2
\]

So the polynomial becomes

\[
x^4 - 10x^3 + 35x^2 - 50x + 24
= u^2 + 10u + 24
\]

Now factor the quadratic:

\[
u^2 + 10u + 24 = (u+4)(u+6)
\]

Substitute back \(u = x^2 - 5x\):

\[
(x^2 - 5x + 4)(x^2 - 5x + 6) = 0
\]

Now factor each quadratic.

First factor:

\[
x^2 - 5x + 4 = (x-1)(x-4)
\]

Second factor:

\[
x^2 - 5x + 6 = (x-2)(x-3)
\]

Thus,

\[
(x-1)(x-4)(x-2)(x-3) = 0
\]

Therefore,

\[
x = 1,\quad x = 2,\quad x = 3,\quad x = 4
\]

All four solutions are real.

\[
\boxed{x = 1,\ 2,\ 3,\ 4}
\]

---

## 2. Solve the system of equations:

\[
\begin{aligned}
2x + y - z &= 8 \\
-x + 3y + 2z &= 7 \\
x + 2y + 3z &= 10
\end{aligned}
\]

Label the equations:

\[
\begin{aligned}
(1)\quad & 2x + y - z = 8 \\
(2)\quad & -x + 3y + 2z = 7 \\
(3)\quad & x + 2y + 3z = 10
\end{aligned}
\]

Add equations \((2)\) and \((3)\):

\[
(-x + 3y + 2z) + (x + 2y + 3z) = 7 + 10
\]

Simplify:

\[
5y + 5z = 17
\]

Divide by 5:

\[
y + z = \frac{17}{5}
\]

So

\[
y = \frac{17}{5} - z
\]

Now use equation \((1)\) and equation \((2)\). Multiply equation \((2)\) by 2:

\[
-2x + 6y + 4z = 14
\]

Add this to equation \((1)\):

\[
(2x + y - z) + (-2x + 6y + 4z) = 8 + 14
\]

Simplify:

\[
7y + 3z = 22
\]

Substitute \(y = \frac{17}{5} - z\):

\[
7\left(\frac{17}{5} - z\right) + 3z = 22
\]

Distribute:

\[
\frac{119}{5} - 7z + 3z = 22
\]

\[
\frac{119}{5} - 4z = 22
\]

Subtract \(\frac{119}{5}\) from both sides:

\[
-4z = 22 - \frac{119}{5}
\]

Write 22 with denominator 5:

\[
22 = \frac{110}{5}
\]

So

\[
-4z = \frac{110}{5} - \frac{119}{5}
\]

\[
-4z = -\frac{9}{5}
\]

Divide by \(-4\):

\[
z = \frac{9}{20}
\]

Now find \(y\):

\[
y = \frac{17}{5} - \frac{9}{20}
\]

Convert \(\frac{17}{5}\) to twentieths:

\[
\frac{17}{5} = \frac{68}{20}
\]

Thus,

\[
y = \frac{68}{20} - \frac{9}{20}
\]

\[
y = \frac{59}{20}
\]

Now find \(x\) using equation \((3)\):

\[
x + 2y + 3z = 10
\]

Substitute \(y = \frac{59}{20}\) and \(z = \frac{9}{20}\):

\[
x + 2\left(\frac{59}{20}\right) + 3\left(\frac{9}{20}\right) = 10
\]

\[
x + \frac{118}{20} + \frac{27}{20} = 10
\]

\[
x + \frac{145}{20} = 10
\]

Convert 10 to twentieths:

\[
10 = \frac{200}{20}
\]

So

\[
x = \frac{200}{20} - \frac{145}{20}
\]

\[
x = \frac{55}{20}
\]

Simplify:

\[
x = \frac{11}{4}
\]

Therefore, the solution is

\[
\boxed{x = \frac{11}{4},\quad y = \frac{59}{20},\quad z = \frac{9}{20}}
\]

---

## 3. Compute the definite integral:

\[
\int_0^\pi x\sin(x)\,dx
\]

Use integration by parts.

Recall:

\[
\int u\,dv = uv - \int v\,du
\]

Let

\[
u = x
\]

and

\[
dv = \sin(x)\,dx
\]

Then

\[
du = dx
\]

and

\[
v = -\cos(x)
\]

Thus,

\[
\int x\sin(x)\,dx = x(-\cos(x)) - \int (-\cos(x))\,dx
\]

\[
= -x\cos(x) + \int \cos(x)\,dx
\]

\[
= -x\cos(x) + \sin(x)
\]

Now evaluate from \(0\) to \(\pi\):

\[
\int_0^\pi x\sin(x)\,dx
=
\left[-x\cos(x) + \sin(x)\right]_0^\pi
\]

Evaluate at \(x = \pi\):

\[
-\pi\cos(\pi) + \sin(\pi)
\]

Since \(\cos(\pi) = -1\) and \(\sin(\pi) = 0\),

\[
-\pi(-1) + 0 = \pi
\]

Evaluate at \(x = 0\):

\[
-0\cos(0) + \sin(0)
\]

Since \(\cos(0) = 1\) and \(\sin(0) = 0\),

\[
0 + 0 = 0
\]

Therefore,

\[
\int_0^\pi x\sin(x)\,dx = \pi - 0
\]

\[
\boxed{\pi}
\]

---

## 4. Solve for \(x\):

\[
\ln(x+1) + \ln(x-1) = \ln(15)
\]

First determine the domain.

For the logarithms to be defined, we need

\[
x+1 > 0
\]

and

\[
x-1 > 0
\]

The second condition is stronger, so

\[
x > 1
\]

Now combine the logarithms on the left:

\[
\ln(x+1) + \ln(x-1) = \ln\big((x+1)(x-1)\big)
\]

So the equation becomes

\[
\ln\big((x+1)(x-1)\big) = \ln(15)
\]

Since the natural logarithm is one-to-one, we can equate the arguments:

\[
(x+1)(x-1) = 15
\]

Use the difference of squares:

\[
x^2 - 1 = 15
\]

Add 1 to both sides:

\[
x^2 = 16
\]

Take square roots:

\[
x = \pm 4
\]

Now apply the domain restriction \(x > 1\).

\[
x = -4
\]

is not allowed, but

\[
x = 4
\]

is allowed.

Check:

\[
\ln(4+1) + \ln(4-1) = \ln(5) + \ln(3) = \ln(15)
\]

So the solution is valid.

\[
\boxed{x = 4}
\]
```