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

::: columns
:::: {.column width=50%}
values

$[-2^{63}, 2^{63})$
::::
:::: {.column width=50%}
operations

`+` `-` `*` `/` `==` `<`
::::
:::
:::::

```{=latex}
\vspace{-0.5em}
```

::::: block

## Bool \centering

::: columns
:::: {.column width=50%}
values

`{false, true}`
::::
:::: {.column width=50%}
operations

`&&` `||` `!`
::::
:::
:::::

```{=latex}
\vspace{-0.5em}
```

::::: block

## String \centering

::: columns
:::: {.column width=50%}
values

strings
::::
:::: {.column width=50%}
operations

`+`, `charAt`, `length`
::::
:::
:::::

```{=latex}
\vspace{-0.5em}
```

::::: block

## List[Int] \centering

::: columns
:::: {.column width=50%}
values

lists of integers
::::
:::: {.column width=50%}
operations

`++`, `map`, `length`
::::
:::
:::::

::::
:::
