---
title: Compiler implementation
---

# What is this course about?

##

::: columns
:::: {.column width=58%}

```{=latex}
\begin{minipage}[c][.5\textheight][c]{\linewidth}
\centering
```

- Building \cemph{your own compiler} step by step
  - Use \cemph{any language} you like
  - Implement \cemphp{Lexer}
  - Implement \cemphp{Parser}
  - Implement \cemphp{LLVM IR generation}
  - Use LLVM framework as backend
- Incremental evolution of source language
  1. Basic untyped expression language
  1. Control flow constructs
  1. Functions
  1. Primitive type system
  1. Structs and arrays
- Theory and practice together

  > More compiler theory on elective courses!
  
- Next semester will re-use developed compiler


```{=latex}
\end{minipage}
```

::::
:::: {.column width=42%}

```{=latex}
\begin{minipage}[c][0.5\textheight][c]{\columnwidth}
```

```{=latex}
\centering
\hspace{4em}
\begin{tikzpicture}[
    ->,>=latex,
    every node/.style={font=\footnotesize,align=left},
    base/.style={minimum width={4em},minimum height={2em},inner sep=1em,outer sep=auto},
    n/.style={base,draw,solid},
    block/.style={n,rectangle},
    tiny block/.style={block,scale=0.5},
    large block/.style={block,minimum width=7em},
    every matrix/.style={row sep=2em,column sep=-1.5em,ampersand replacement=\&,every node/.style={block}},
  ]

  \matrix {
  \& \node [large block] (src) {Source}; \& \\
  \& \node [large block] (tok) {Tokens}; \& \\
  \& \node [large block] (ast) {AST}; \& \\
  \& \node [large block] (ir)  {LLVM IR}; \& \\
  \& \node [large block] (exe) {Executable}; \& \\
  };
  \graph [use existing nodes] {
    src -> ["\hspace{4em} \cemphp{Lexer}"]   tok
        -> ["\hspace{4em} \cemphp{Parser}"]  ast
        -> ["\hspace{4em} \cemphp{IR gen}"] ir
        -> ["\hspace{4em} LLVM backend"]     exe
  };
\end{tikzpicture}
```

```{=latex}
\end{minipage}
```

::::
:::

# Organization

::: columns

:::: {.column width=55%}

## Structure \centering

- ~14 weeks, 1.5 classes per week
- Mixed lecture-seminar format
- 5 language extensions to implement
  1. Basic untyped expression language (6 weeks)
  1. Control flow constructs (2 weeks)
  1. Functions (2 weeks)
  1. Primitive type system (2 weeks)
  1. Structs and arrays (2 weeks)
- Final grade is based on implemented extensions
  - **5** --- all 5 extensions
  - **4** --- 4 out of 5 extensions
  - **3** --- 3 out of 5 extensions

::::
:::: {.column width=45%}

```{=latex}
\begin{minipage}[c][.7\textheight][c]{\linewidth}
\centering
\qrcode[height=3.5cm]{https://nsu-syspro.github.io/courses/translators/}
\vspace{1em}
\small
```
<https://nsu-syspro.github.io/courses/translators/>
```{=latex}
\end{minipage}
```

::::

:::

# Compiler architecture

## Traditional compilation pipeline \centering

::: columns
:::: {.column width=58%}

- Front end
  - Lexing (Token stream)
  - Parsing (Abstract Syntax Tree, AST)
  - Type checking (Typed AST)
  - Semantic checking
  - Desugaring
  - Translation to intermediate representation (IR)
- Middle end
  - Machine-independent optimizations and analyses
- Back end
  - Lowering to target arch IR
  - Instruction selection
  - Instruction scheduling
  - Register allocation
  - Machine code generation


::::
:::: {.column width=42%}

```{=latex}
\begin{minipage}[c][0.7\textheight][c]{\columnwidth}
```

```{=latex}
\centering
\hspace{4em}
\begin{tikzpicture}[
    ->,>=latex,
    every node/.style={font=\footnotesize,align=left},
    base/.style={minimum width={4em},minimum height={2em},inner sep=1em,outer sep=auto},
    n/.style={base,draw,solid},
    block/.style={n,rectangle},
    tiny block/.style={block,scale=0.5},
    large block/.style={block,minimum width=7em},
    every matrix/.style={row sep=2em,column sep=-1.5em,ampersand replacement=\&,every node/.style={block}},
  ]

  \matrix {
  \& \node [large block] (front) {Front end}; \& \\
  \& \node [large block] (middle) {Middle end}; \& \\
  \& \node [large block] (back) {Back end}; \& \\
  };
  \graph [use existing nodes] {
    front -> middle -> back
  };
  \draw[->] (middle.south) to[bend right=120,distance=7em] (middle.north);
\end{tikzpicture}
```

```{=latex}
\end{minipage}
```

::::
:::

# Compiler architecture

## Implementation \centering

::: columns
:::: {.column width=60%}

- We will develop front end for LLVM
  - \cemphp{Lexer}
  - \cemphp{Parser}
  - \cempht{Type checker} (later)
  - \cemphp{LLVM IR generation}
- LLVM framework handles middle and back end
  - Optimization
  - Code generation
- All front end stages can be
  - Part of single front end (recommended)
  - Separate programs chained together
- All intermediate formats can be dumped and checked
  - Tokens (JSON)
  - AST (JSON)
  - LLVM IR (.ll or .bc)


::::
:::: {.column width=40%}

```{=latex}
\begin{minipage}[c][0.8\textheight][c]{\columnwidth}
```

```{=latex}
\centering
\hspace{4em}
\begin{tikzpicture}[
    ->,>=latex,
    every node/.style={font=\footnotesize,align=left},
    base/.style={minimum width={4em},minimum height={2em},inner sep=1em,outer sep=auto},
    n/.style={base,draw,solid},
    block/.style={n,rectangle},
    tiny block/.style={block,scale=0.5},
    large block/.style={block,minimum width=7em},
    every matrix/.style={row sep=2em,column sep=-1.5em,ampersand replacement=\&,every node/.style={block}},
  ]

  \matrix {
  \& \node [large block] (src) {Source}; \& \\
  \& \node [large block] (tok) {Tokens}; \& \\
  \& \node [large block] (ast) {AST}; \& \\
  \& \node [large block] (ir)  {LLVM IR}; \& \\
  \& \node [large block] (exe) {Executable}; \& \\
  };
  \graph [use existing nodes] {
    src -> ["\hspace{4em} \cemphp{Lexer}"]   tok
        -> ["\hspace{4em} \cemphp{Parser}"]  ast
        -> ["\hspace{4em} \cemphp{IR gen}"] ir
        -> ["\hspace{4em} LLVM backend"]     exe
  };
  \draw[->] (ast.east) to[bend right=45,distance=2em] node[right] {\cempht{Type checker}} (ast.east);
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
