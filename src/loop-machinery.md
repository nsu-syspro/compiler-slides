---
title: Loop transformations
subtitle: Compiler implementation
---

# What is a loop?

::: columns
:::: {.column width=55%}

## Definition \centering

- A loop is a subset of CFG nodes with two properties
- Induced subgraph is strongly connected: every node reachable from every other
- All edges from outside the subset point to the same node, the header
- Header dominates all other loop nodes
- A cycle without such a header is irreducible control flow, not a loop

::::
:::: {.column width=41%}

## A realistic CFG \centering

\centering

```{=latex}
\begin{tikzpicture}
  [->,>=latex,
   every node/.style={font=\footnotesize,align=center},
   base/.style={draw,rounded corners,minimum width=4.5em,minimum height=1.6em},
   every matrix/.style={row sep=1.6em,column sep=1.2em,ampersand replacement=\&,every node/.style={base}},
   lab/.style={font=\scriptsize}]
  \matrix {
  \& \node (entry) {entry}; \& \& \\
  \& \node (header) {\texttt{i < n ?}}; \& \& \node (exit) {exit}; \\
  \& \node (body) {\texttt{if (cond)}\\ body}; \& \\ \\
  \& \node (latch) {\texttt{++i}}; \& \& \\
  };
  \draw [->] (entry) -- (header);
  \draw [->] (header) -- node[left,lab] {true} (body);
  \draw [->] (body) -- (latch);
  \draw [->] (latch) edge[bend left] node[right,lab] {next} (header);
  \draw [->] (header) -- node[above,lab] {false} (exit);
\end{tikzpicture}
```

::::
:::

# Loop vocabulary

::: columns
:::: {.column width=55%}

## Terms \centering

- Entering block (loop predecessor) has an edge into the loop
- Preheader: entering block whose only edge is to the header
- Preheader dominates the loop without belonging to it
- Latch: loop node with an edge to the header
- Backedge: the edge from latch to header
- Exiting block has an edge out, its target is an exit block
- Loops sharing a header nest into each other

::::
:::: {.column width=41%}

## Anatomy \centering

\centering

![](images/loop-machinery/loop-terminology.pdf)

::::
:::

# References

- [LLVM Loop Terminology (and Canonical Forms)](https://llvm.org/docs/LoopTerminology.html)
- [Nikita Popov: LLVM Scalar Evolution](https://www.npopov.com/2023/10/03/LLVM-Scalar-evolution.html)
