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
- Loops sharing a header nest into each other
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

- Loops are either disjoint or one is nested inside the other
- The loop hierarchy forms a forest
- Two logical loops sharing a header are a single loop in LLVM
- The inner loop is lost for loop optimizations
- `LoopSimplify` ensures separate headers for outer and inner loop

::::
:::: {.column width=50%}

```{=latex}
\begin{minipage}[c][.8\textheight][c]{\linewidth}
\centering
\begin{onlyenv}<1>
```

![](images/loop-anatomy/loop-merge.pdf)

```{=latex}
\end{onlyenv}
\begin{onlyenv}<2>
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

- A cycle without a dominating header is not a loop
- Reducible: the CFG collapses to one node by merging
  sequences, acyclic branches and self-loops
- Irreducible flow can appear at any nesting level
- `fix-irreducible` inserts new headers, not in default pipelines
- C sources: two loops entering each other, Duff's device

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
