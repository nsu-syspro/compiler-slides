---
title: "AST design"
---

# AST design

##

::: columns
:::: {.column width=55%}

- How the same abstract syntax tree is represented in
  - Imperative languages (C, Zig)
  - Object-oriented languages (Java, Scala)
  - Functional languages (OCaml)
- Memory management, construction from a parser, traversal
- How production compilers represent their ASTs
  - CPython, GCC, rustc, Go, Clang, GHC, \dots
- Semantic checks and IR generation as traversals

::::
:::: {.column width=42%}

```{=latex}
\begin{minipage}[c][.4\textheight][c]{\linewidth}
\centering
```

```{=latex}
\hspace{2em}
\begin{tikzpicture}[
    ->,>=latex,
    every node/.style={font=\footnotesize,align=left},
    base/.style={minimum width={4em},minimum height={2em},inner sep=0.8em,outer sep=auto},
    n/.style={base,draw,solid},
    block/.style={n,rectangle},
    every matrix/.style={row sep=2em,column sep=1.5em,ampersand replacement=\&,every node/.style={block}},
  ]

  \matrix {
  \& \node [block] (add) {$+$}; \& \\
  \node [block] (a) {$a$}; \& \node [block] (b) {$b$}; \\
  };
  \graph [use existing nodes] {
    add -> a; add -> b;
  };
\end{tikzpicture}
```

```{=latex}
\end{minipage}
```

::::
:::

# Abstract syntax trees

## Grammar and tree \centering

::: columns
:::: {.column width=50%}

$$
e \; ::= \; n \; | \; x \; | \; e_1 + e_2 \; | \; e_1 \cdot e_2
$$

- A parse tree records every derivation step
- An \cemph{abstract} syntax tree keeps only the structure
  - Parentheses, precedence, spelling of keywords: gone
- The tree shape mirrors the grammar productions
- Every later stage of the compiler works on this tree
  - Semantic checks, transformations, IR generation

::::
:::: {.column width=48%}

```{=latex}
\begin{minipage}[c][.55\textheight][c]{\linewidth}
\centering
```

\vspace{1em}

$(a + b) \cdot c$

\vspace{0.5em}

```{=latex}
\begin{tikzpicture}[
    ->,>=latex,
    every node/.style={font=\footnotesize,align=left},
    base/.style={minimum width={4em},minimum height={2em},inner sep=0.8em,outer sep=auto},
    n/.style={base,draw,solid},
    block/.style={n,rectangle},
    every matrix/.style={row sep=2em,column sep=1.5em,ampersand replacement=\&,every node/.style={block}},
  ]

  \matrix {
  \& \& \node [block] (mul) {$\cdot$}; \& \\
  \& \node [block] (add) {$+$}; \& \& \node [block] (c) {$c$}; \\
  \node [block] (a) {$a$}; \& \node [block] (b) {$b$}; \\
  };
  \graph [use existing nodes] {
    mul -> add; mul -> c; add -> a; add -> b;
  };
\end{tikzpicture}
```

```{=latex}
\end{minipage}
```

::::
:::

# One AST, three families

##

::: columns
:::: {.column width=31%}

```{=latex}
\begin{minipage}[c][.55\textheight][c]{\linewidth}
\centering
```

\vspace{2em}

\cemph{Imperative}

C, Zig

```{=latex}
\end{minipage}
```

::::
:::: {.column width=31%}

```{=latex}
\begin{minipage}[c][.55\textheight][c]{\linewidth}
\centering
```

\vspace{2em}

\cemph{Object-oriented}

Java, Scala

```{=latex}
\end{minipage}
```

::::
:::: {.column width=31%}

```{=latex}
\begin{minipage}[c][.55\textheight][c]{\linewidth}
\centering
```

\vspace{2em}

\cemph{Functional}

OCaml

```{=latex}
\end{minipage}
```

::::
:::

# One AST, three families

##

```{=latex}
\lstset{style=small}
```

::: columns
:::: {.column width=31%}

```c
enum expr_kind {
    EXPR_INT,
    EXPR_VAR,
    EXPR_ADD,
    EXPR_MUL,
};

struct expr {
    enum expr_kind kind;
    int64_t int_val;
    const char *var_name;
    struct expr *l, *r;
};
```

\vspace{0.3em}
\centering
\cemph{tagged union}

::::
:::: {.column width=31%}

```java
sealed interface Expr
  permits IntLit, Var,
          Add, Mul { }

record IntLit(long value)
  implements Expr { }
record Var(String name)
  implements Expr { }
record Add(Expr l, Expr r)
  implements Expr { }
record Mul(Expr l, Expr r)
  implements Expr { }
```

\vspace{0.3em}
\centering
\cemphp{class hierarchy}

::::
:::: {.column width=31%}

```ocaml
type expr =
  | Int of int64
  | Var of string
  | Add of expr * expr
  | Mul of expr * expr
```

\vspace{2em}

\centering
$\Longrightarrow$

\cemph{ADT}

algebraic data type

::::
:::

# Memory management

## Who owns the nodes? \centering

::: columns
:::: {.column width=31%}

\cemph{Manual / arena}

- Nodes are heap-allocated and never freed individually
- Arena (bump) allocator: allocate nodes one after another,
  free the whole arena when the AST dies
- In Zig the allocator is an explicit argument of every
  allocation
- In C: `malloc`, or wrap an arena in a few macros

- Parents own children; the tree is a DAG-free ownership tree

::::
:::: {.column width=31%}

\cemphp{Garbage collection}

- JVM / .NET / Go: `new` and forget
- Nodes reference each other freely
- No ownership question, at the cost of
  GC pauses and memory overhead

- Immutable records fit GC particularly well:
  no write barriers on old objects

::::
:::: {.column width=31%}

\cemphp{Garbage collection}

- OCaml: minor heap allocation is a pointer bump;
  short-lived ASTs mostly die young
- Values are immutable by default
- Sharing instead of copying is safe: subtrees
  can be reused across trees

::::
:::

# Building the AST from a recursive descent parser

##

```{=latex}
\lstset{style=small}
```

::: columns
:::: {.column width=31%}

\cemph{C / Zig}

- Parse functions return nodes or
  pointers to nodes

```c
struct expr *e =
  make_add(parse_add(),
           parse_mul());
```

- The node constructor is a plain
  function; the allocation strategy
  (malloc vs arena) is invisible
  to the parser

::::
:::: {.column width=31%}

\cemphp{Java / Scala}

- Parse methods return `Expr`

```java
Expr parseAdd() {
    var l = parseMul();
    while (next is "+") {
        var r = parseMul();
        l = new Add(l, r);
    }
    return l;
}
```

- Factory methods and builders when
  node construction needs more than
  field assignment

::::
:::: {.column width=31%}

\cemph{OCaml}

- Parse functions return values

```ocaml
(* left fold over the
   multiplicative level *)
let rec parse_mul () =
  match op with
  | Add -> Add (l, r)
```

- Constructed bottom-up; values,
  not builders

- Parser combinators are the
  functional idiom --- details in
  the Haskell course next semester

::::
:::

# Traversal

##

```{=latex}
\lstset{style=small}
```

::: columns
:::: {.column width=31%}

\cemph{Switch on the tag}

```c
int64_t eval
  (const struct expr *e) {
  switch (e->kind) {
  case EXPR_INT:
    return e->int_val;
  case EXPR_VAR:
    return lookup(name);
  case EXPR_ADD:
    return eval(e->l)
         + eval(e->r);
  case EXPR_MUL:
    return eval(e->l)
         * eval(e->r);
  }
}
```

- No exhaustiveness check

::::
:::: {.column width=31%}

\cemphp{Visitor / double dispatch}

```java
interface Visitor<R> {
  R visitInt(IntLit e);
  R visitVar(Var e);
  R visitAdd(Add e);
  R visitMul(Mul e);
}

record Add(Expr l, Expr r)
    implements Expr {
  R accept(Visitor<R> v) {
    return v.visitAdd(this);
  }
}
```

- One method per node class

::::
:::: {.column width=31%}

\cemph{Pattern matching}

```ocaml
let rec eval env =
  function
  | Int n  -> n
  | Var x  -> find x env
  | Add (l, r) ->
    eval env l
    + eval env r
  | Mul (l, r) ->
    eval env l
    * eval env r
```

- Exhaustiveness checked by the
  compiler: forgetting a variant
  is a warning or an error

::::
:::

# Traversal

## Kinds of traversal \centering

::: columns
:::: {.column width=55%}

- \cemph{Compute a value} --- evaluation, constant folding
- \cemph{Transform} --- desugaring, lowering to a smaller core
- \cemph{Emit} --- IR generation: expression $\to$ value,
  statement $\to$ effect
- \cemph{Inspect} --- name resolution, semantic checks

\vspace{1.5em}

Each kind works with any of the three data structures;
the data structure decides \cemph{how} the traversal is written,
not \cemph{whether} it can be written

- \cemph{add operation}: easy everywhere
- \cemph{add node kind}: touches either every operation
  (switch, match) or every node class (visitor)

::::
:::: {.column width=40%}

representation $\times$ traversal

\vspace{0.8em}

\begin{tabular}{p{5.2em}ll}
\hline
 & \cemph{add op} & \cemphp{add kind} \\
\hline
tagged union & easy & all switches \\
class hier.  & easy & all classes \\
ADT          & easy & all matches \\
\hline
\end{tabular}

\vspace{1.5em}

All three choices pay the same price somewhere ---
the differences are in \cemph{where} the compiler
concentrates the cost

::::
:::

# What real compilers do

## Representation by language family \centering

```{=latex}
\lstset{style=small}
```

::: columns
:::: {.column width=31%}

\cemph{Tagged unions}

- CPython --- `A_Expr`, op enums
- GCC --- `tree_code` over `union tree_node`
- rustc --- `enum ExprKind`
- Go --- `ir.Op` over a node struct
- LLVM SelectionDAG --- `ISD::NodeType`
- Zig --- `std.zig.Ast`, tag per node

::::
:::: {.column width=31%}

\cemph{ADTs}

- GHC --- `HsExpr` per pass
- OCaml compiler --- `Parsetree`
- Scala 3 --- `Tree` ADT
- F\# --- `SynExpr`
- Elm --- `Expr`

::::
:::: {.column width=31%}

\cemphp{Class hierarchies}

- Clang --- `Stmt`/`Expr` hierarchy
- Swift --- `Syntax` protocol tree
- Roslyn --- green/red trees
- javac --- `JCTree` subclasses
- V8 --- `AstNode` subclasses

::::
:::

# What real compilers do

## Deep dives \centering

::: columns
:::: {.column width=31%}

```{=latex}
\begin{minipage}[c][.6\textheight][c]{\linewidth}
\centering
```

\vspace{3em}

\cemph{Clang}

class hierarchy + arena

\vspace{1em}

```{=latex}
\end{minipage}
```

::::
:::: {.column width=31%}

```{=latex}
\begin{minipage}[c][.6\textheight][c]{\linewidth}
\centering
```

\vspace{3em}

\cemph{rustc}

enum + arena

\vspace{1em}

```{=latex}
\end{minipage}
```

::::
:::: {.column width=31%}

```{=latex}
\begin{minipage}[c][.6\textheight][c]{\linewidth}
\centering
```

\vspace{3em}

\cemph{GHC}

ADT parameterized by pass

\vspace{1em}

```{=latex}
\end{minipage}
```

::::
:::

# Clang

## class hierarchy + arena \centering

```{=latex}
\lstset{style=small}
```

::: columns
:::: {.column width=48%}

- `Stmt`/`Expr` --- about a hundred node classes,
  one per syntactic form
- Every node carries a kind tag: cheap `isa`/`dyn_cast`
  without RTTI, needed for visitor-style dispatch
- Uniform child storage: `BinaryOperator` keeps
  `Stmt *SubExprs[2]` --- children typed `Stmt*`,
  not dedicated fields
- All nodes allocated in the `ASTContext` arena;
  freed once, when the translation unit is done
- Traversal: `StmtVisitor` --- visitor over
  the class hierarchy

::::
:::: {.column width=48%}

```{=latex}
\centering
```

```cpp
class BinaryOperator : public Expr {
  enum { LHS, RHS, END_EXPR };
  Stmt *SubExprs[END_EXPR];

public:
  typedef BinaryOperatorKind Opcode;

  const Expr *getLHS() const {
    return cast<Expr>(SubExprs[LHS]);
  }
};
```

\vspace{0.8em}

\qrcode[height=2.2cm]{https://github.com/llvm/llvm-project/blob/main/clang/include/clang/AST/Expr.h}

[clang/AST/Expr.h]{.small}

::::
:::

# rustc

## enum + arena \centering

```{=latex}
\lstset{style=small}
```

::: columns
:::: {.column width=48%}

- `enum ExprKind` --- about a hundred variants,
  one per syntactic form
- Children are `Box<Expr>` and `ThinVec<Box<Expr>>` ---
  boxed, since enum variants must have one size
- Allocated in per-phase arenas: the AST is built,
  used, and dropped together
- AST is only the first tree: lowered to HIR,
  then to MIR --- each tree much smaller than
  the last
- Traversal: `match` on the variant, often via
  `#[derive]`-generated visitors

::::
:::: {.column width=48%}

```{=latex}
\centering
```

```rust
pub enum ExprKind {
  /// A literal (e.g., `1`).
  Lit(token::Lit),
  /// A binary operation
  /// (e.g., `a + b`).
  Binary(BinOp, Box<Expr>,
         Box<Expr>),
  /// An `if` block, with an
  /// optional `else` block.
  If(Box<Expr>, Box<Block>,
     Option<Box<Expr>>),
  // ... about 100 variants
}
```

\vspace{0.8em}

\qrcode[height=2.2cm]{https://github.com/rust-lang/rust/blob/master/compiler/rustc_ast/src/ast.rs}

[compiler/rustc\_ast/src/ast.rs]{.small}

::::
:::

# GHC

## ADT parameterized by pass \centering

```{=latex}
\lstset{style=small}
```

::: columns
:::: {.column width=48%}

- One ADT per syntactic category: `HsExpr`,
  `HsPat`, `HsType`, \dots
- The ADT is parameterized by the \cemph{compiler
  pass}: `GhcPs` (parsed), `GhcRn` (renamed),
  `GhcTc` (typechecked)
- Type families attach per-phase payloads:
  after renaming a binary application records
  its \cemph{fixity}; after typechecking the same
  variant cannot appear at all
- The type system makes illegal tree states
  unrepresentable: a typechecked `OpApp` does
  not typecheck
- Traversal: plain `match`, one walk per pass

::::
:::: {.column width=48%}

```{=latex}
\centering
```

```haskell
-- OpApp not present in GhcTc pass
type instance XOpApp GhcPs =
  NoExtField
type instance XOpApp GhcRn = Fixity
type instance XOpApp GhcTc =
  DataConCantHappen
```

\vspace{0.8em}

Same constructor, different payloads per
pass --- and one variant is \cemph{gone} after
typechecking

\vspace{0.8em}

\qrcode[height=2.2cm]{https://github.com/ghc/ghc/blob/master/compiler/GHC/Hs/Expr.hs}

[compiler/GHC/Hs/Expr.hs]{.small}

::::
:::

# References

## Sources \centering

::: columns
:::: {.column width=31%}

\vspace{1em}

\qrcode[height=2.8cm]{https://github.com/llvm/llvm-project/blob/main/clang/include/clang/AST/Expr.h}

\vspace{0.3em}

[clang/AST/Expr.h]{.small}

::::
:::: {.column width=31%}

\vspace{1em}

\qrcode[height=2.8cm]{https://github.com/rust-lang/rust/blob/master/compiler/rustc_ast/src/ast.rs}

\vspace{0.3em}

[compiler/rustc\_ast/src/ast.rs]{.small}

::::
:::: {.column width=31%}

\vspace{1em}

\qrcode[height=2.8cm]{https://github.com/ghc/ghc/blob/master/compiler/GHC/Hs/Expr.hs}

\vspace{0.3em}

[compiler/GHC/Hs/Expr.hs]{.small}

::::
:::

# Semantic checks and codegen are traversals

## Every stage is a walk over the same tree \centering

::: columns
:::: {.column width=45%}

- \cemph{Name resolution} --- find declarations,
  reject undefined variables
- \cemph{Type checking} --- compute and compare types
  (a later grammar stage)
- \cemph{Constant evaluation} --- fold `2 + 3 * 4`
- \cemph{IR generation} --- lower the tree to LLVM IR

\vspace{1.5em}

Each of these is a traversal; the three families
only differ in how the walk is written:

- switch on tag
- visitor / double dispatch
- pattern match

::::
:::: {.column width=45%}

```{=latex}
\begin{minipage}[c][.6\textheight][c]{\linewidth}
\centering
```

```{=latex}
\hspace{1em}
\begin{tikzpicture}[
    ->,>=latex,
    every node/.style={font=\footnotesize,align=left},
    base/.style={minimum width={4em},minimum height={2em},inner sep=0.8em,outer sep=auto},
    n/.style={base,draw,solid},
    block/.style={n,rectangle},
    every matrix/.style={row sep=1.8em,column sep=1.2em,ampersand replacement=\&,every node/.style={block}},
  ]

  \matrix {
  \& \node [block] (add) {$+$}; \& \\
  \node [block] (a) {$a$}; \& \node [block] (b) {$b$}; \\
  };
  \graph [use existing nodes] {
    add -> a; add -> b;
  };
\end{tikzpicture}
```

\vspace{0.8em}

resolve $a$, $b$ --- a traversal

fold $2+3$ --- a traversal

emit code --- a traversal

```{=latex}
\end{minipage}
```

::::
:::

# IR generation for expressions

## Same traversal, three styles \centering

::: columns
:::: {.column width=31%}

\cemph{Switch}

```c
/* x = a + b */
LLVMValueRef emit(const
    struct expr *e) {
    switch (e->kind) {
    case EXPR_INT:
        return LLVMConstInt(
          i64, e->int_val, 0);
    case EXPR_VAR:
        return load_var(
          e->var_name);
    case EXPR_ADD:
        return LLVMBuildAdd(b,
          emit(e->l),
          emit(e->r), "");
    ...
    }
}
```

::::
:::: {.column width=31%}

\cemphp{Visitor}

```java
class EmitVisitor
    implements Visitor<Value> {

  Value visitInt(IntLit e) {
    return i64(e.value);
  }

  Value visitVar(Var e) {
    return load(e.name);
  }

  Value visitAdd(Add e) {
    return builder.add(
      e.l.accept(this),
      e.r.accept(this));
  }
  ...
}
```

::::
:::: {.column width=31%}

\cemph{Match}

```ocaml
let rec emit = function
  | Int n -> const i64 n
  | Var x -> load x
  | Add (l, r) ->
      build add (emit l)
                (emit r)
  | Mul (l, r) ->
      build mul (emit l)
                (emit r)
```

\vspace{1em}

expressions $\to$ values

statements $\to$ effects

::::
:::

# What it emits

## `x = a + b;` \centering

::: columns
:::: {.column width=42%}

- Expressions produce \cemph{values}
- Statements produce \cemph{effects}

\vspace{1.5em}

- `alloca` reserves a stack slot per variable
- `load` reads the slot into a register value
- `store` writes a value back to the slot
- No registers are assigned by us --- LLVM
  handles register allocation

\vspace{1.5em}

The `alloca`/load/store discipline is
all we need; the optimizer turns it into
SSA form

::::
:::: {.column width=50%}

```llvm
%x = alloca i64
%a = alloca i64
%b = alloca i64

; a + b
%1 = load i64, ptr %a
%2 = load i64, ptr %b
%3 = add i64 %1, %2

; x =
store i64 %3, ptr %x
```

::::
:::

# if

## Terminators and basic blocks \centering

::: columns
:::: {.column width=42%}

- `if` splits the control flow
- The function body is a list of
  \cemph{basic blocks}, each ending with a
  \cemph{terminator}
- `br` is the terminator for branches:
  a condition and two targets

\vspace{1.5em}

- The emitter creates the blocks,
  remembers which is which,
  fills them in order

::::
:::: {.column width=50%}

```{=latex}
\begin{minipage}[c][.55\textheight][c]{\linewidth}
\centering
```

```{=latex}
\begin{tikzpicture}[
    ->,>=latex,
    every node/.style={font=\footnotesize,align=left},
    base/.style={minimum width={5em},minimum height={2em},inner sep=0.8em,outer sep=auto},
    n/.style={base,draw,solid},
    block/.style={n,rectangle},
    every matrix/.style={row sep=1.6em,column sep=1.5em,ampersand replacement=\&,every node/.style={block}},
  ]

  \matrix {
  \& \node [block] (entry) {entry}; \& \\
  \node [block] (then) {then}; \& \& \node [block] (else) {else}; \\
  \& \node [block] (merge) {merge}; \\
  };
  \graph [use existing nodes] {
    entry -> then; entry -> else;
    then -> merge; else -> merge;
  };
\end{tikzpicture}
```

\vspace{0.8em}

```llvm
br i1 %cond, label %then, label %else
```

```{=latex}
\end{minipage}
```

::::
:::

# while

## A cycle in the control flow graph \centering

::: columns
:::: {.column width=42%}

- Same building blocks: blocks, terminators, `br`
- The back edge makes it a loop

\vspace{1.5em}

- New blocks are appended; the emitter
  tracks the \cemph{current} block explicitly,
  switching to it when control flow merges

::::
:::: {.column width=50%}

```{=latex}
\begin{minipage}[c][.55\textheight][c]{\linewidth}
\centering
```

```{=latex}
\begin{tikzpicture}[
    ->,>=latex,
    every node/.style={font=\footnotesize,align=left},
    base/.style={minimum width={5em},minimum height={2em},inner sep=0.8em,outer sep=auto},
    n/.style={base,draw,solid},
    block/.style={n,rectangle},
    every matrix/.style={row sep=1.6em,column sep=1.5em,ampersand replacement=\&,every node/.style={block}},
  ]

  \matrix {
  \& \node [block] (entry) {entry}; \& \\
  \& \node [block] (cond) {cond}; \& \\
  \node [block] (body) {body}; \& \& \node [block] (exit) {exit}; \\
  };
  \graph [use existing nodes] {
    entry -> cond; cond -> body;
    cond -> exit; body -> cond;
  };
\end{tikzpicture}
```

\vspace{0.8em}

```llvm
cond:
  br i1 %c, label %body, label %exit
body:
  ...
  br label %cond
```

```{=latex}
\end{minipage}
```

::::
:::

# break and continue

## The targets live in the emitter, not in the tree \centering

::: columns
:::: {.column width=45%}

- `break` / `continue` are just jumps ---
  but to blocks of the \cemph{enclosing loop}
- The node itself does not know its target
- The emitter keeps a stack of
  `(break target, continue target)` pairs,
  pushed by `while` / `for`, popped after

\vspace{1.5em}

- Same idea as symbol tables:
  the emitter carries context that
  the AST does not contain

::::
:::: {.column width=45%}

```{=latex}
\begin{minipage}[c][.55\textheight][c]{\linewidth}
\centering
```

```{=latex}
\begin{tikzpicture}[
    ->,>=latex,
    every node/.style={font=\footnotesize,align=left},
    base/.style={minimum width={5em},minimum height={2em},inner sep=0.8em,outer sep=auto},
    n/.style={base,draw,solid},
    block/.style={n,rectangle},
    every matrix/.style={row sep=1.6em,column sep=1.5em,ampersand replacement=\&,every node/.style={block}},
  ]

  \matrix {
  \& \node [block] (cond) {cond}; \& \\
  \node [block] (body) {body}; \& \& \node [block] (exit) {exit}; \\
  };
  \graph [use existing nodes] {
    cond -> body; cond -> exit; body -> cond;
  };
  \draw[->,dashed] (body) to[bend right=35] node[below right] {\cemphp{break}} (exit);
  \draw[->,dashed] (body) to[bend left=15] node[above left] {\cemph{continue}} (cond);
\end{tikzpicture}
```

\vspace{0.8em}

`break` $\to$ exit block

`continue` $\to$ condition block

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
