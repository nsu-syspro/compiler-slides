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

# Static vs dynamic

```{=latex}
\begin{minipage}[t][5.2cm][t]{\linewidth}
```

::: columns
:::: {.column width=50%}

```{=latex}
\onslide<1->
```

## Static typing \centering

```{=latex}
\onslide<2->
```

- Operations are checked at compile time, before the program runs
- A program is accepted or rejected without ever executing it
- The compiler must know the type of every expression in advance
- Every type is written by the programmer or inferred by the compiler
- Costs a type checker in the compiler; checks are free at run time

::::
:::: {.column width=50%}

```{=latex}
\onslide<1->
```

## Dynamic typing \centering

```{=latex}
\onslide<2->
```

- Operations are checked at run time, against the values they receive
- The same program can work on some inputs and fail on others
- Every value carries a tag recording its type at run time
- Every operation checks the tag first, then proceeds or fails
- Costs memory for tags and a check on every operation at run time

::::
:::

```{=latex}
\end{minipage}
\vspace{0.4em}
\begin{minipage}[t][2.4cm][c]{\linewidth}
\centering
\onslide<3->
\langaxis<4->[Static][Dynamic]{Haskell/^-1.0, C\slash Rust/_-1.0, Scala\slash Java/^-0.7, Go\slash C++/_-0.7, TypeScript/0.05, Python\slash JavaScript/^0.75, Lua/_0.75, Bash/_1.0}
\end{minipage}
```


# Strong vs weak

```{=latex}
\begin{minipage}[t][5.2cm][t]{\linewidth}
```

::: columns
:::: {.column width=50%}

```{=latex}
\onslide<1->
```

## Strong typing \centering

```{=latex}
\onslide<2->
```

- An operation on mismatched operand types is an error
- Static systems reject it at compile time, dynamic ones raise it at run time
- Every conversion is written by the programmer, visible in the source
- The checker only compares types, it never converts them
- Costs no conversion machinery: every conversion lives in the source

::::
:::: {.column width=50%}

```{=latex}
\onslide<1->
```

## Weak typing \centering

```{=latex}
\onslide<2->
```

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
\onslide<3->\langaxis<4->[Strong][Weak]{Haskell/^-0.9, Rust\slash Go/_-1.0, Python/_-0.65, Java/^-0.45, Scala/_-0.35, TypeScript/^-0.2, Lua/^0.3, C/_0.6, C++/^0.7, JavaScript/_0.9, Bash/^1.0}
\end{minipage}
```

# Explicit vs implicit

```{=latex}
\begin{minipage}[t][5.2cm][t]{\linewidth}
```

::: columns
:::: {.column width=50%}

```{=latex}
\onslide<1->
```

## Explicit types \centering

```{=latex}
\onslide<2->
```

- Types are written out on declarations by the programmer
- The checker only reads and compares the types it is given
- Costs a simple checker, at the price of typing effort
- Signatures double as documentation at every boundary
- Errors point directly at the mismatched declaration

::::
:::: {.column width=50%}

```{=latex}
\onslide<1->
```

## Implicit types \centering

```{=latex}
\onslide<2->
```

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
\onslide<3->\langaxis<4->[Explicit][Implicit]{C/^-0.95, Java/_-0.8, C++/_-0.45, Rust\slash Go/^0.0, TypeScript/_0.15, Scala/^0.35, Python/_0.45, Haskell/_0.75, Lua\slash JavaScript/^0.85, Bash/_1.0}
\end{minipage}
```

# Nominal vs structural

```{=latex}
\begin{minipage}[t][5.2cm][t]{\linewidth}
```

::: columns
:::: {.column width=50%}

```{=latex}
\onslide<1->
```

## Nominal typing \centering

```{=latex}
\onslide<2->
```

- A type is its declared name: `class A`, `struct A`
- Two types are the same only if they come from one declaration
- Identical definitions remain different types
  (C++ one-definition rule)
- The checker compares declarations, not definitions
- Costs little: identity is name equality, renaming changes nothing

::::
:::: {.column width=50%}

```{=latex}
\onslide<1->
```

## Structural typing \centering

```{=latex}
\onslide<2->
```

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
\onslide<3->\langaxis<4->[Nominal][Structural]{Java/^-1.0, Haskell/^-0.7, C++/_-0.7, Rust/^-0.45, Scala/_-0.45, Go/^0.0, C/_-0.1, Bash/_0.4, Python/^0.6, Lua/_0.7, TypeScript/_0.9, JavaScript/^1.0}
\end{minipage}
```

# Sound vs unsound

```{=latex}
\begin{minipage}[t][5.2cm][t]{\linewidth}
```

::: columns
:::: {.column width=50%}

```{=latex}
\onslide<1->
```

## Sound type system \centering

```{=latex}
\onslide<2->
```

- If the checker accepts the program, it cannot go wrong at run time
- A type error is a caught exception, never memory corruption
- Runtime tags catch what the checker missed: Java casts, Python tags
- Proven types let the compiler skip tag checks: `a + b` is one instruction
- Costs soundness proofs and discipline with every new feature

::::
:::: {.column width=50%}

```{=latex}
\onslide<1->
```

## Unsound type system \centering

```{=latex}
\onslide<2->
```

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
\onslide<3->\langaxis<4->[Sound][Unsound]{Haskell/^-0.9, Rust/_-0.9, Go/_-0.75, Python/^-0.55, Java/_-0.55, Lua/^-0.25, JavaScript/_-0.25, Scala/_0.05, TypeScript/^0.4, C\slash C++/_0.9, Bash/^1.0}
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

# Type checker

::: columns
:::: {.column width=50%}

## Pipeline \centering

- \cempht{Type checker} sits between name resolution and code generation
- Input: the AST with every name resolved to its declaration
- Output: the same AST, each expression annotated with its type
- Diagnostics for every mismatch, checking does not stop at the first
- Reuses the scope stack built by name resolution

::::
:::: {.column width=50%}

```{=latex}
\begin{minipage}[c][.7\textheight][c]{\linewidth}
\centering
```

```{=latex}
\begin{tikzpicture}[
    ->,>=latex,
    every node/.style={align=center},
    base/.style={draw,minimum height=2em,minimum width=11em,inner sep=0.5em},
  ]
  \node[base] (p) {Parser};
  \node[base,below=2em of p] (nr) {Name resolution};
  \node[base,draw=CtpTeal,very thick,text=CtpTeal,below=2em of nr] (tc) {Type checking};
  \node[base,below=2em of tc] (ir) {IR generation};
  \draw (p)  -- (nr) node[midway,left,font=\small] {AST};
  \draw (nr) -- (tc) node[midway,left,font=\small] {resolved AST};
  \draw (tc) -- (ir) node[midway,left,font=\small] {typed AST};
  \draw (tc) -- (ir) node[midway,right,font=\small] {diagnostics};
\end{tikzpicture}
```

```{=latex}
\end{minipage}
```

::::
:::

# Type checker

::: columns
:::: {.column width=50%}

```{=latex}
\begin{onlyenv}<1-4>
```

::: block

## Traversal \centering \phantom{g}

- The checker visits the tree bottom-up, one node at a time
- A variable node reads its type from the environment
- An operator node fetches the operator's signature
- Operand types are matched against the parameter types
- The result type becomes the type of the whole expression

:::

```{=latex}
\end{onlyenv}
\begin{onlyenv}<5->
```

::: block

## Strong and weak \centering

- The same mismatch reaches the checker in every language
- A strong checker \textcolor{CtpRed}{stops}: it reports
  \textcolor{CtpRed}{\texttt{Double != Int}} and rejects the program
- A weak checker \textcolor{CtpPeach}{inserts a conversion} and
  continues: \texttt{2.0} becomes \texttt{Int}
- The compile succeeds; the fraction is lost silently at run time

:::

```{=latex}
\end{onlyenv}
```

::::
:::: {.column width=50%}

```{=latex}
\begin{minipage}[c][.7\textheight][c]{\linewidth}
\centering
```

```{=latex}
\begin{tikzpicture}[
    xshift=8em,
    c/.style={circle,draw,minimum size={3em-\pgflinewidth},inner sep=0,outer sep=auto},
    t/.style={font=\ttfamily},
  ]
  \matrix (m) [ampersand replacement=\&,row sep=1em,column sep=1em] {
    \& \node[c,selected on=<{3,6}>,mismatch on=<{4,5}>] (op) {{+}}; \& \\
    \node[c,selected on=<2>] (l) {{1}}; \& \& \node[c,t,draw=CtpPeach,text=CtpPeach,visible on=<6>] (conv) {$\simeq$}; \\
    \& \& \node[c,t,visible on=<6>] (rb) {{2.0}}; \\
  };
  \node[c,t,selected on=<2>,visible on=<1-5>] (rt) at (conv) {{2.0}};
  \graph [use existing nodes] {
    (op) -- (l),
    (op) -- [visible on=<1-5>] (rt),
    (op) -- [visible on=<6>] (conv),
    (conv) -- [visible on=<6>] (rb)
  };
  \node[t,visible on=<3->,above=1em of op] {{+: (Int, Int) -> Int}};
  \node[t,visible on=<6>,right=2em of op] {{Int}};
  \node[t,visible on=<2->,below=1em of l] {{Int}};
  \node[t,visible on=<2-3>,below=1em of rt] {{Double}};
  \node[t,CtpRed,visible on=<{4,5}>,below=1em of rt] {{Double != Int}};
  \node[t,visible on=<6>,below=1em of rb] {{Double}};
  \node[t,left=1em of l] {\phantom{Double}};
  \node[t,CtpPeach,visible on=<6>,right=1em of conv,align=center] {Int\\ $\uparrow$\\ Double};
\end{tikzpicture}
```

```{=latex}
\end{minipage}
```

::::
:::

# Type checker

::: columns
:::: {.column width=50%}

## Bidirectional \centering

- Types propagate in both directions: results flow up, expectations
  flow down
- \cempht{Synthesis} computes a type bottom-up, from the operands
- \textcolor{CtpMauve}{Checking} verifies an expression top-down
  against a type from the context
- Type annotations and parameters pass expected types down
- The same literal can get different types in different contexts

::::
:::: {.column width=50%}

```{=latex}
\begin{minipage}[c][.7\textheight][c]{\linewidth}
\centering
```

```{=latex}
\begin{tikzpicture}[
    c/.style={circle,draw,minimum size={3em-\pgflinewidth},inner sep=0,outer sep=auto},
    t/.style={font=\ttfamily},
  ]
  \matrix (m) [ampersand replacement=\&,row sep=1em,column sep=1em] {
    \& \node[c,t] (var) {{var}}; \& \\
    \node[c,t,selected mauve on=<2>] (ann) {{x}}; \& \& \node[c,t,selected mauve on=<3>] (lit) {{1}}; \\
  };
  \graph [use existing nodes] {
    (var) -- (ann),
    (var) -- (lit),
    (ann) -> [dashed, CtpMauve, visible on=<2->] (lit)
  };
  \node[t,above=1em of var] {{var x: Double = 1}};
  \node[t,below=1em of ann] {{Double}};
  \node[t,visible on=<3>,below=1em of lit] {{Double}};
\end{tikzpicture}
```

```{=latex}
\end{minipage}
```

::::
:::

# Type checker

::: columns
:::: {.column width=50%}

## Nominal vs structural \centering

- Nominal: the checker compares declarations, not definitions
- Structural: the checker walks both definitions in lockstep
- Fields compared pairwise, recursion into their types
- Primitive types stop the walk, names anchor recursive types
- \textcolor{CtpRed}{Tree $\neq$ BST} nominally
- \textcolor{CtpGreen}{Tree $=$ BST} structurally

::::
:::: {.column width=50%}

```{=latex}
\begin{minipage}[c][.7\textheight][c]{\linewidth}
\centering
```

```{=latex}
\begin{tikzpicture}[
    c/.style={circle,draw,minimum size={3em-\pgflinewidth},inner sep=0,outer sep=auto},
    s/.style={circle,draw,minimum size={2.5em-\pgflinewidth},inner sep=0,outer sep=auto,font=\small\ttfamily},
    t/.style={font=\ttfamily},
    node distance=0.5em,
  ]
  \matrix (a) [ampersand replacement=\&,row sep=1em,column sep=2.5em] {
    \& \node[c,t] (tr) {{\{ \}}}; \& \\
    \node[s] (tl) {l}; \& \node[s] (tx) {x}; \& \node[s] (trr) {r}; \\
  };
  \matrix (b) [ampersand replacement=\&,row sep=1em,column sep=2.5em,below=4em of a] {
    \& \node[c,t] (br) {{\{ \}}}; \& \\
    \node[s] (bl) {l}; \& \node[s] (by) {y}; \& \node[s] (brr) {r}; \\
  };
  \node[t,above=of tr] (tn) {Tree};
  \node[t,above=of br] (bn) {BST};
  \node[t,below=of tl] {Tree};
  \node[t,below=of tx] {Int};
  \node[t,below=of trr] {Tree};
  \node[t,below=of bl] {BST};
  \node[t,below=of by] {Int};
  \node[t,below=of brr] {BST};
  \graph [use existing nodes] {
    (tr) -- (tl), (tr) -- (tx), (tr) -- (trr),
    (br) -- (bl), (br) -- (by), (br) -- (brr)
  };
  \draw[dashed,->] (tl) to [bend left=60] (tr);
  \draw[dashed,->] (trr) to [bend right=60] (tr);
  \draw[dashed,->] (bl) to [bend left=60] (br);
  \draw[dashed,->] (brr) to [bend right=60] (br);
\end{tikzpicture}
```

```{=latex}
\end{minipage}
```

::::
:::

# {.plain}

\centering
```{=latex}
{\fontsize{48pt}{7.2}\selectfont Q\&A }
```
