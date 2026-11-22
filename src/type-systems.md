---
title: Type systems
subtitle: Compiler implementation
---

# What is a type

::: columns
:::: {.column width=50%}

## Definition \centering

- A type is a set of values and a set of operations valid on those values
- A type system assigns types to expressions, variables, storage locations
- A program is well-typed when every operation is applied to values of a type that supports it
- Programs violating this are ill-typed and are rejected

::::
:::: {.column width=50%}

::::: block

## Int64 \centering

| values | operations |
|:--:|:--:|
| integers in $[-2^{63}, 2^{63})$ | `+` `-` `*` `/` `==` `<` |

:::::

```{=latex}
\vspace{-0.5em}
```

::::: block

## Bool \centering

| values | operations |
|:--:|:--:|
| `{false, true}` | `&&` `||` `!` |

:::::

```{=latex}
\vspace{-0.5em}
```

::::: block

## String \centering

| values | operations |
|:--:|:--:|
| sequences of characters | `+`, `charAt`, `length` |

:::::

```{=latex}
\vspace{-0.5em}
```

::::: block

## List[Int] \centering

| values | operations |
|:--:|:--:|
| lists of integers | `++`, `map`, `length` |

:::::

::::
:::
