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
\langaxis<2->[Static][Dynamic]{Haskell/^-1.0, C\slash Rust/_-1.0, Scala\slash Java/^-0.7, Go\slash C++/_-0.7, TypeScript/0.05, Python\slash JavaScript/^0.75, Lua/_0.75, Bash/_1.0}
\end{minipage}
```


# Strong vs weak typing

```{=latex}
\begin{minipage}[t][5.2cm][t]{\linewidth}
```

::: columns
:::: {.column width=50%}

## Strong checking \centering

- An operation on mismatched operand types is an error
- Static systems reject it at compile time, dynamic ones raise it at run time
- Every conversion is written by the programmer, visible in the source
- The checker only compares types, it never converts them
- Costs no conversion machinery: every conversion lives in the source

::::
:::: {.column width=50%}

## Weak checking \centering

- An operation on mismatched operand types silently converts them
- C widens `int` to `double` at compile time, inserting the conversion code
- JavaScript converts at run time: `"1" + 1` is `"11"`, `"1" - 1` is `0`
- The compiler or runtime carries a conversion rule for every type pair
- Costs conversion machinery in the compiler or the runtime

::::
:::

```{=latex}
\end{minipage}
\vspace{0.4em}
\begin{minipage}[t][2.4cm][c]{\linewidth}
\centering
\langaxis<2->[Strong][Weak]{Haskell/^-0.9, Rust\slash Go/_-1.0, Python/_-0.65, Java/^-0.45, Scala/_-0.35, TypeScript/^-0.2, Lua/^0.3, C/_0.6, C++/^0.7, JavaScript/_0.9, Bash/^1.0}
\end{minipage}
```

# Explicit vs implicit types

```{=latex}
\begin{minipage}[t][5.2cm][t]{\linewidth}
```

::: columns
:::: {.column width=50%}

## Explicit types \centering

- Types are written out on declarations by the programmer
- The checker only reads and compares the types it is given
- Costs a simple checker, at the price of typing effort
- Signatures double as documentation at every boundary
- Errors point directly at the mismatched declaration

::::
:::: {.column width=50%}

## Inferred types \centering

- Types are reconstructed by the compiler, never written
- Hindley–Milner infers whole functions, Rust and Go infer locals
- Costs an inference engine: unification or dataflow analysis
- What must be annotated becomes a design decision
- Errors can point far away from the actual mistake

::::
:::

```{=latex}
\end{minipage}
\vspace{0.4em}
\begin{minipage}[t][2.4cm][c]{\linewidth}
\centering
\langaxis<2->[Explicit][Implicit]{C/^-0.95, Java/_-0.8, C++/_-0.45, Rust\slash Go/^0.0, TypeScript/_0.15, Scala/^0.35, Python/_0.45, Haskell/_0.75, Lua\slash JavaScript/^0.85, Bash/_1.0}
\end{minipage}
```

# Nominal vs structural typing

```{=latex}
\begin{minipage}[t][5.2cm][t]{\linewidth}
```

::: columns
:::: {.column width=50%}

## Nominal typing \centering

- A type is its declared name: `class A`, `struct A`
- Two types are the same only if they come from one declaration
- Identical definitions remain different types (C++ ODR)
- The checker compares declarations, not definitions
- Costs little: identity is name equality, renaming changes nothing

::::
:::: {.column width=50%}

## Structural typing \centering

- A type is its shape: the fields and methods it provides
- Two types are the same if their shapes match (TypeScript, Go interfaces)
- The checker compares definitions member by member, recursively
- Costs a shape-comparison engine with generics and recursion
- Allows accidental matches: unrelated same-shape types unify

::::
:::

```{=latex}
\end{minipage}
\vspace{0.4em}
\begin{minipage}[t][2.4cm][c]{\linewidth}
\centering
\langaxis<2->[Nominal][Structural]{Java/^-1.0, Haskell/^-0.7, C++/_-0.7, Rust/^-0.45, Scala/_-0.45, Go/^0.0, C/_-0.1, Bash/_0.4, Python/^0.6, Lua/_0.7, TypeScript/_0.9, JavaScript/^1.0}
\end{minipage}
```

# Sound vs unsound checking

```{=latex}
\begin{minipage}[t][5.2cm][t]{\linewidth}
```

::: columns
:::: {.column width=50%}

## Sound checking \centering

- If the checker accepts the program, it cannot go wrong at run time
- A type error is a caught exception, never memory corruption
- Runtime tags catch what the checker missed: Java casts, Python tags
- Proven types let the compiler skip tag checks: `a + b` is one instruction
- Costs soundness proofs and discipline with every new feature

::::
:::: {.column width=50%}

## Unsound checking \centering

- A checked program can still go wrong at run time
- Mistakes become undefined behavior instead of errors (C, C++)
- A lying checker certifies programs that then crash: TypeScript's `TypeError`
- Nothing can be safely skipped: runtime checks everywhere, or UB semantics
- Costs a cheaper checker: the programmer or the runtime pays instead

::::
:::

```{=latex}
\end{minipage}
\vspace{0.4em}
\begin{minipage}[t][2.4cm][c]{\linewidth}
\centering
\langaxis<2->[Sound][Unsound]{Haskell/^-0.9, Rust/_-0.9, Go/_-0.75, Python/^-0.55, Java/_-0.55, Lua/^-0.25, JavaScript/_-0.25, Scala/_0.05, TypeScript/^0.4, C\slash C++/_0.9, Bash/^1.0}
\end{minipage}
```

# Type systems

```{=latex}
\begin{center}
\langaxiscompactset\langaxis[Static][Dynamic]{Haskell/^-1.0, C\slash Rust/_-1.0, Scala\slash Java/^-0.7, Go\slash C++/_-0.7, TypeScript/0.05, Python\slash JavaScript/^0.75, Lua/_0.75, Bash/_1.0}

\vspace{-0.5em}
\langaxiscompactset\langaxis[Strong][Weak]{Haskell/^-0.9, Rust\slash Go/_-1.0, Python/_-0.65, Java/^-0.45, Scala/_-0.35, TypeScript/^-0.2, Lua/^0.3, C/_0.6, C++/^0.7, JavaScript/_0.9, Bash/^1.0}

\vspace{-0.5em}
\langaxiscompactset\langaxis[Explicit][Implicit]{C/^-0.95, Java/_-0.8, C++/_-0.45, Rust\slash Go/^0.0, TypeScript/_0.15, Scala/^0.35, Python/_0.45, Haskell/_0.75, Lua\slash JavaScript/^0.85, Bash/_1.0}

\vspace{-0.5em}
\langaxiscompactset\langaxis[Nominal][Structural]{Java/^-1.0, Haskell/^-0.7, C++/_-0.7, Rust/^-0.45, Scala/_-0.45, Go/^0.0, C/_-0.1, Bash/_0.4, Python/^0.6, Lua/_0.7, TypeScript/_0.9, JavaScript/^1.0}

\vspace{-0.5em}
\langaxiscompactset\langaxis[Sound][Unsound]{Haskell/^-0.9, Rust/_-0.9, Go/_-0.75, Python/^-0.55, Java/_-0.55, Lua/^-0.25, JavaScript/_-0.25, Scala/_0.05, TypeScript/^0.4, C\slash C++/_0.9, Bash/^1.0}
\end{center}
```
# {.plain}

\centering
```{=latex}
{\fontsize{48pt}{7.2}\selectfont Q\&A }
```
