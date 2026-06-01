# Exercise 02 — Linear Transformations

## Part (a): Fundamental Principles of a Linear Transformation

A **linear transformation** is a function `T` that maps vectors from one vector space to another while preserving the operations of **vector addition** and **scalar multiplication**. These two preservation properties are the absolutely essential, defining principles.

### 1. Additivity (Preservation of Vector Addition)

For any two vectors `a` and `b` in the domain:

    f(a + b) = f(a) + f(b)

This means that whether you add first and then transform, or transform first and then add, you get exactly the same result. For example, if `f` is a matrix multiplication `f(x) = Ax`, then:

    f(a + b) = A(a + b) = Aa + Ab = f(a) + f(b)

Matrix multiplication distributes over vector addition, which is why matrix multiplication always represents a linear transformation.

### 2. Homogeneity (Preservation of Scalar Multiplication)

For any vector `a` and any scalar `c`:

    f(c · a) = c · f(a)

This means scaling a vector before transforming gives the same result as transforming first and then scaling. Again, for a matrix `A`:

    f(c · a) = A(c · a) = c(Aa) = c · f(a)

### 3. Consequences: f(0) = 0

The condition `f(0) = 0` is **not an independent requirement** — it follows directly from either additivity or homogeneity. Here are two simple proofs:

**From additivity:**
    f(0) = f(0 + 0) = f(0) + f(0)
    Subtracting f(0) from both sides:  0 = f(0)

**From homogeneity** (with scalar c = 0):
    f(0 · a) = 0 · f(a) = 0
    So  f(0) = 0

This means any function that does *not* map the zero vector to the zero vector **cannot** be a linear transformation.

---

## Part (b): Distinguishing Linear Transformations from Non-Linear "Almost-Linear" Functions

### The Crucial Distinction

In mathematics (particularly **linear algebra**), the term **"linear transformation"** has a very specific, strict meaning. It does *not* mean something that graphs as a straight line — it means a function that satisfies **both** additivity and homogeneity. This is a much stronger condition than what is often colloquially called "linear" in other contexts (such as a **linear equation** `y = mx + b` in high-school algebra).

### Why f1(x) = mx *is* a Linear Transformation

Let `f(x) = mx`, which can also be written as the matrix multiplication `f(x) = [m] · x`.

- **Additivity:**  f(a + b) = m(a + b) = ma + mb = f(a) + f(b)  ✔️
- **Homogeneity:**  f(c · a) = m(c · a) = c(ma) = c · f(a)  ✔️
- **Zero mapping:**  f(0) = m · 0 = 0  ✔️

All three conditions hold. Therefore, `f(x) = mx` is a true linear transformation.

### Why f2(x) = mx + b *is NOT* a Linear Transformation (when b ≠ 0)

Let `f(x) = mx + b` where `b ≠ 0`.

- **Additivity fails:**

  f(a + b) = m(a + b) + b  =  ma + mb + b

  f(a) + f(b) = (ma + b) + (mb + b)  =  ma + mb + 2b

  These are equal only when b = 0:

  ma + mb + b ≠ ma + mb + 2b   when b ≠ 0

- **Homogeneity fails:**

  f(c · x) = m(cx) + b  =  cmx + b

  c · f(x) = c(mx + b)  =  cmx + cb

  These are equal only when b = cb, i.e., when b = 0 (or c = 1, but this must hold for *all* scalars c).

- **The zero-mapping test** (the simplest disproof):

  f(0) = m · 0 + b = b

  Since b ≠ 0, we have f(0) ≠ 0, which alone is sufficient to prove that f is **not** a linear transformation.

**Conclusion:** When `b ≠ 0`, the function `f(x) = mx + b` is called an **affine transformation**, not a linear transformation. An affine transformation can be viewed as a linear transformation followed by a translation (shift). Geometrically, its graph *is* a straight line, but mathematically it does not satisfy the axioms of linearity.

### Summary Table

| Function | Additivity | Homogeneity | f(0) = 0 | Classification |
|---|---|---|---|---|
| f(x) = mx | ✅ Yes | ✅ Yes | ✅ Yes | Linear transformation |
| f(x) = mx + b (b ≠ 0) | ❌ No | ❌ No | ❌ No (f(0) = b) | Affine transformation |
| f(x) = mx + b (b = 0) | ✅ Yes | ✅ Yes | ✅ Yes | Linear transformation |

### Key Takeaway

The term "linear" in "linear transformation" is **mathematically precise**: it requires preservation of vector addition and scalar multiplication, which forces `f(0) = 0`. Many things that people *call* "linear" (like `y = mx + b`) are actually **affine** — they are "linear" only in the sense that they produce straight lines when graphed, but they do not satisfy the algebraic definition of linearity. This is one of the most common sources of confusion when students encounter linear algebra.
