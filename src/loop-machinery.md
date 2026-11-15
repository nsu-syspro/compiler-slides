---
title: Loop transformations
subtitle: Compiler implementation
---

# What is a loop?

::: columns
:::: {.column width=55%}

- A loop is a subset of CFG nodes with two properties
- Induced subgraph is strongly connected: every node reachable from every other
- All edges from outside the subset point to the same node, the header
- Header dominates all other loop nodes
- A cycle without such a header is irreducible control flow, not a loop

::::
:::: {.column width=41%}

![](images/loop-machinery/loop-single.pdf)

::::
:::

*Detection: `LoopInfo`, built on dominator trees over the CFG*

# Loop vocabulary

::: columns
:::: {.column width=55%}

- Entering block (loop predecessor) has an edge into the loop
- Preheader: entering block whose only edge is to the header
- Preheader dominates the loop without belonging to it
- Latch: loop node with an edge to the header
- Backedge: the edge from latch to header
- Exiting block has an edge out, its target is an exit block
- Loops sharing a header nest into each other

::::
:::: {.column width=41%}

![](images/loop-machinery/loop-terminology.pdf)

::::
:::

# References

- [LLVM Loop Terminology (and Canonical Forms)](https://llvm.org/docs/LoopTerminology.html)
- [Nikita Popov: LLVM Scalar Evolution](https://www.npopov.com/2023/10/03/LLVM-Scalar-evolution.html)
