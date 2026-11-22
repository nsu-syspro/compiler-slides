---
title: Type systems
subtitle: Compiler implementation
---

# Definitions

::: columns
:::: {.column width=50%}

. . .

## Type \centering

. . .

A type is a set of `\cemph{`{=latex} values`}`{=latex}
and a set of `\cemph{`{=latex} operations `}`{=latex} valid on those values

. . .

## Type system \centering

. . .

A type system assigns types to expressions and variables

. . .

## Type checking \centering

Type checking is semantic analysis that verifies every operation against the types of its operands

::::
:::: {.column width=45%}

. . .

::::: block

## Int64 \centering

. . .

::: columns
:::: {.column width=50%}
\centering
$[-2^{63}, 2^{63})$
::::
:::: {.column width=50%}
\centering
`+` `-` `*` `/` `==` `<` `\phantom{$2^{63}$}`{=latex}
::::
:::
:::::

. . .

\vspace{1em}

::::: block

## Bool \centering

. . .

::: columns
:::: {.column width=50%}
\centering
`{false, true}`
::::
:::: {.column width=50%}
\centering
`&&` `||` `!`
::::
:::
:::::

. . .

\vspace{1em}

::::: block

## String \centering

. . .

::: columns
:::: {.column width=50%}
\centering
strings
::::
:::: {.column width=50%}
\centering
`+`, `charAt`, `length`
::::
:::
:::::

. . .

\vspace{1em}

::::: block

## List[Int] \centering

. . .

::: columns
:::: {.column width=50%}
\centering
lists of integers
::::
:::: {.column width=50%}
\centering
`++`, `map`, `length`
::::
:::
:::::

::::
:::

<!-- static vs dynamic: option A joined -->

# Static vs dynamic checking

::: columns
:::: {.column width=50%}

## Static checking \centering

- Checked at compile time, before the program runs
- A program is accepted or rejected without ever executing it
- The compiler must know the type of every expression
- A type checker to write and maintain, types written out by the programmer or inferred
- Checks are free at run time

::::
:::: {.column width=50%}

## Dynamic checking \centering

- Operations are checked at run time, on the values they actually receive
- The same program can work on some inputs and fail on others
- Every value carries a tag saying what it is
- Every operation first checks the tag
- Memory for tags and a check on each operation, on each execution

::::
:::
