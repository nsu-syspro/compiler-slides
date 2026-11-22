---
title: Type systems
subtitle: Compiler implementation
---

# What is a type {.fragile}

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
\small
```

::::: block

## Int64 \centering

- values: integers in [-2^63, 2^63)
- operations: `+` `-` `*` `/` `==` `<`

:::::

::::: block

## Bool \centering

- values: {false, true}
- operations: `&&` `||` `!`

:::::

::::: block

## double (C, Java) \centering

- values: IEEE 754 floating-point numbers
- operations: `+` `-` `*` `/` `==`

:::::

::::: block

## String (Java) \centering

- values: sequences of characters
- operations: `+` concatenation, `length`, `charAt`

:::::

::::: block

## List[Int] (Scala) \centering

- values: sequences of integers
- operations: `::` prepend, `map`, `length`

:::::

```{=latex}
\end{minipage}
```

::::
:::
