---
title: Loop anatomy
subtitle: Compiler implementation
---

# Terminology

::: columns
:::: {.column width=50%}

## Definition \centering

- A loop is a subset of CFG nodes with two properties
- Induced subgraph is strongly connected: every node reachable from every other
- All edges from outside the subset point to the same node, the header
- Header dominates all other loop nodes
- A cycle without such a header is irreducible control flow, not a loop

::::
:::: {.column width=50%}

```{=latex}
\begin{minipage}[c][.8\textheight][c]{\linewidth}
\centering
```

![](images/loop-anatomy/loop-terminology.pdf)

```{=latex}
\end{minipage}
```

::::
:::

# Terminology

::: columns
:::: {.column width=50%}

## Anatomy \centering

- Entering block (loop predecessor) has an edge into the loop
- Latch: loop node with an edge to the header
- Backedge: the edge from latch to header
- Exiting block has an edge out, its target is an exit block
- Preheader: entering block whose only edge is to the header
- Preheader dominates the loop without belonging to it

::::
:::: {.column width=50%}

```{=latex}
\begin{minipage}[c][.8\textheight][c]{\linewidth}
\centering
\begin{onlyenv}<1>
```

![](images/loop-anatomy/loop-terminology.pdf)

```{=latex}
\end{onlyenv}
\begin{onlyenv}<2>
```

![](images/loop-anatomy/loop-single.pdf)

```{=latex}
\end{onlyenv}
\begin{onlyenv}<3>
```

![](images/loop-anatomy/loop-nested.pdf)

```{=latex}
\end{onlyenv}
\begin{onlyenv}<4>
```

![](images/loop-anatomy/loop-nonmaximal.pdf)

```{=latex}
\end{onlyenv}
\end{minipage}
```

::::
:::

# Shared headers

::: columns
:::: {.column width=50%}

## Nesting \centering

```{=latex}
\lstset{style=highlight}
```

- Loops are either disjoint or one is nested inside the other
- The loop hierarchy forms a forest
- Two logical loops sharing a header are a single loop in LLVM
- `loop-simplify` ensures separate headers for outer and inner loop

::::
:::: {.column width=50%}

```{=latex}
\begin{minipage}[c][.8\textheight][c]{\linewidth}
\centering
\begin{onlyenv}<1>
```

![](images/loop-anatomy/loop-nonmaximal.pdf)

```{=latex}
\end{onlyenv}
\begin{onlyenv}<2>
```

![](images/loop-anatomy/loop-merge.pdf)

```{=latex}
\end{onlyenv}
\begin{onlyenv}<3>
```

![](images/loop-anatomy/loop-separate.pdf)

```{=latex}
\end{onlyenv}
\end{minipage}
```

::::
:::

# Irreducible control flow

::: columns
:::: {.column width=50%}

## No header \centering

```{=latex}
\lstset{style=highlight}
```

- A cycle without a dominating header is not a loop
- Reducible: the CFG collapses to one node by merging
  sequences, acyclic branches and self-loops
- Irreducible flow can appear at any nesting level
- `fix-irreducible` inserts new headers, not in default pipelines
- C sources: two loops entering each other, [Duff's device](https://en.wikipedia.org/wiki/Duff%27s_device)

::::
:::: {.column width=50%}

```{=latex}
\begin{minipage}[c][.8\textheight][c]{\linewidth}
\centering
```

![](images/loop-anatomy/loop-irreducible.pdf)

```{=latex}
\end{minipage}
```

::::
:::

# Loop Simplify Form

::: columns
:::: {.column width=50%}

## Simplify \centering

```{=latex}
\lstset{style=highlight}
```

- Canonical form that loop passes can rely on
- A preheader
- A single backedge, hence a single latch
- Dedicated exits: no exit block has a predecessor outside the loop
- Then all exit blocks are dominated by the header
- Ensured by the `loop-simplify` pass
- Added automatically by the pass manager before a `LoopPass`

::::
:::: {.column width=50%}

```{=latex}
\begin{minipage}[c][.8\textheight][c]{\linewidth}
\centering
```

```{=latex}
\begin{tikzpicture}[
    ->,>=latex,
    every node/.style={font=\footnotesize,align=left},
    base/.style={minimum width={2em},minimum height={2em},inner sep=0.8em,outer sep=auto},
    n/.style={base,draw,solid},
    region/.style={draw=CtpRed,rounded corners,dashed,inner sep=0.5em},
  ]
  \node[n] (pre)    at ( 0.0, 3.3) {pre};
  \node[n] (header) at ( 0.0, 2.0) {header};
  \node[n] (body)   at (-1.4, 0.9) {body};
  \node[n] (latch)  at (-1.4,-0.2) {latch};
  \node[n] (exit)   at ( 1.5, 0.9) {exit};
  \node[region,fit=(header)(body)(latch),label={below:\footnotesize loop}] {};
  \draw (pre) -- (header);
  \draw (header) -- (body);
  \draw (body) -- (latch);
  \draw (latch.west) .. controls (-2.7,-0.2) and (-2.7,2.0) .. (header.west);
  \draw (header) -- (exit);
\end{tikzpicture}
```

```{=latex}
\end{minipage}
```

::::
:::

# Loop Closed SSA

::: columns
:::: {.column width=48%}

## LCSSA \centering

```{=latex}
\lstset{style=highlight}
```

- All values defined in a loop are used only inside this loop
- Loop-closing PHI: single-entry PHI at each exit block
- Outside users are exactly the loop-closing PHIs
- Transformations update only these PHIs (e.g. unswitching copies the loop)
- Ensured by the `lcssa` pass, cleaned up later by `instcombine`
- Every expression then lives in at most one loop

::::
:::: {.column width=48%}

```{=latex}
\begin{minipage}[c][.8\textheight][c]{\linewidth}
\centering
\vspace{0.5em}
\begin{columns}[T]
\begin{column}{0.48\linewidth}
\centering
before
\end{column}
\begin{column}{0.48\linewidth}
\centering
after
\end{column}
\end{columns}
\vspace{0.5em}
```

::: columns
:::: {.column width=48%}

```c
for (...) {
  if (c) X1 = ...
  else   X2 = ...
  X3 = phi(X1, X2)
}
... = X3 + 4
```

::::
:::: {.column width=48%}

```c
for (...) {
  if (c) X1 = ...
  else   X2 = ...
  X3 = phi(X1, X2)
}
X4 = phi(X3)
... = X4 + 4
```

::::
:::

```{=latex}
\end{minipage}
```

::::
:::

# Rotated loops

::: columns
:::: {.column width=50%}

## Rotation \centering

```{=latex}
\lstset{style=highlight}
```

- `loop-rotate` converts loops into do-while style
- Valid only if the body provably executes at least once
- Otherwise a runtime guard is inserted
- Enables hoisting invariants (e.g. loads) into the preheader
- Restores Loop Simplify Form afterwards: preheader, dedicated exits

::::
:::: {.column width=50%}

```{=latex}
\begin{minipage}[c][.8\textheight][c]{\linewidth}
\centering
\scriptsize
\begin{columns}[T]
\begin{column}{0.48\linewidth}
\centering
before
\end{column}
\begin{column}{0.48\linewidth}
\centering
after
\end{column}
\end{columns}
\vspace{0.5em}
```

::: columns
:::: {.column width=48%}

```{=latex}
\begin{onlyenv}<1-2>
```

```c
for (i = 0; i < n; ++i) {
  body;
}
```

```{=latex}
\end{onlyenv}
\begin{onlyenv}<3>
```

```c
for (i = 0; i < n; ++i) {
  v = *p;
  use(v);
}
```

```{=latex}
\end{onlyenv}
```

::::
:::: {.column width=48%}

```{=latex}
\begin{onlyenv}<1>
```

```c
i = 0;
do {
  body;
  ++i;
} while (i < n);
```

```{=latex}
\end{onlyenv}
\begin{onlyenv}<2>
```

```c
i = 0;
if (n > 0) {
  do {
    body;
    ++i;
  } while (i < n);
}
```

```{=latex}
\end{onlyenv}
\begin{onlyenv}<3>
```

```c
if (n > 0) {
  v = *p;
  i = 0;
  do {
    use(v);
    ++i;
  } while (i < n);
}
```

```{=latex}
\end{onlyenv}
```

::::
:::

```{=latex}
\end{minipage}
```

::::
:::

# References

::: columns
:::: {.column width=50%}

```{=latex}
\begin{minipage}[c][.6\textheight][c]{\linewidth}
\centering
\qrcode[height=3.5cm]{https://llvm.org/docs/LoopTerminology.html}
\vspace{1em}
\small
```
<https://llvm.org/docs/LoopTerminology.html>  
\ 
```{=latex}
\end{minipage}
```

::::
:::: {.column width=50%}

```{=latex}
\begin{minipage}[c][.6\textheight][c]{\linewidth}
\centering
\qrcode[height=3.5cm]{https://www.npopov.com/2023/10/03/LLVM-Scalar-evolution.html}
\vspace{1em}
\small
```
`\phantom{y}`{=latex}<https://www.npopov.com/2023/10/03/LLVM-Scalar-evolution.html>
```{=latex}
\end{minipage}
```

::::
:::

# {.plain}

\centering
```{=latex}
{\fontsize{48pt}{7.2}\selectfont Q\&A }
```
