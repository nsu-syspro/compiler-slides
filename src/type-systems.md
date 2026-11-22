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

```{=latex}
\begin{minipage}[t][5.2cm][t]{\linewidth}
```

::: columns
:::: {.column width=50%}

## Static checking \centering

- Checked at compile time, before the program runs
- A program is accepted or rejected without ever executing it
- The compiler must know the type of every expression
- Every type is written out by the programmer or inferred
- Costs a type checker in the compiler, checks are free at run time

::::
:::: {.column width=50%}

## Dynamic checking \centering

- Checked at run time, on the values they actually receive
- The same program can work on some inputs and fail on others
- Every value carries a tag saying what it is
- Every operation first checks the tag
- Costs memory for tags and a check on each operation, on each execution

::::
:::

```{=latex}
\end{minipage}
\vspace{0.4em}
\begin{minipage}[t][2.4cm][c]{\linewidth}
\centering
\langaxis<2->[Static][Dynamic]{Haskell/-1.0, Rust/_-0.95, Scala/-0.75, Java/-0.8, C/-0.6, Go/-0.45, C++/-0.35, TypeScript/0.05, Python/0.6, Lua/0.8, JavaScript/0.95, Bash/_1.0}
\end{minipage}
```

# Axes overview

```{=latex}
\begin{center}
\langaxiscompactset\langaxis[Static][Dynamic]{Haskell/-1.0, Rust/_-0.95, Scala/-0.75, Java/-0.8, C/-0.6, Go/-0.45, C++/-0.35, TypeScript/0.05, Python/0.6, Lua/0.8, JavaScript/0.95, Bash/_1.0}

\vspace{0.35em}
\langaxiscompactset\langaxis[Strong][Weak]{Haskell/^-1.0, Rust/_-0.9, Go/^-0.8, Python/_-0.65, Java/^-0.5, Scala/_-0.35, TypeScript/^-0.25, Lua/^0.3, C/_0.6, C++/^0.7, JavaScript/_0.9, Bash/^1.0}

\vspace{0.35em}
\langaxiscompactset\langaxis[Explicit][Implicit]{C/^-0.95, Java/_-0.8, Go/^-0.6, C++/_-0.45, Rust/^0.2, TypeScript/_0.15, Scala/^0.4, Python/_0.45, Lua/^0.62, Haskell/_0.75, JavaScript/^0.92, Bash/_1.0}

\vspace{0.35em}
\langaxiscompactset\langaxis[Nominal][Structural]{Java/^-1.0, C++/_-0.7, Haskell/^-0.75, Rust/_-0.5, Scala/^-0.35, Go/_0.0, C/^0.4, Bash/_0.4, Python/^0.6, Lua/_0.7, TypeScript/_0.9, JavaScript/^1.0}

\vspace{0.35em}
\langaxiscompactset\langaxis[Sound][Unsound]{Haskell/^-1.0, Rust/_-0.85, Go/^-0.7, Java/_-0.3, Scala/^0.15, TypeScript/_0.35, Python/^0.4, Lua/_0.6, JavaScript/^0.75, C/_0.8, C++/_0.95, Bash/^1.0}
\end{center}
```
