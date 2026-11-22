---
title: Type systems
subtitle: Compiler implementation
---

# What is a type

::: columns
:::: {.column width=50%}

## Definition \centering

- A type is a set of values and a set of operations valid on those values
- `Int64`: values in [-2^63, 2^63), operations `+` `-` `*` `/` `==` `<`
- `Bool`: values {false, true}, operations `&&` `||` `!`
- A type system is a set of rules assigning types to expressions, variables, storage locations
- The rules define which operations apply to which types

::::
:::: {.column width=50%}

```{=latex}
\begin{minipage}[c][.8\textheight][c]{\linewidth}
\centering
\small
```

```c
int64_t a = f();
int64_t b = a * 2;   // arithmetic ops
bool c = b == 0;     // comparison ops
bool d = c || !b;
d + 1;               // ill-typed
```

```{=latex}
\end{minipage}
```

::::
:::
