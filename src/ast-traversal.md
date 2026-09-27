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
- Traversal: where does the operation live, and what does it cost
- Visitor, switch, pattern match, and why external
  traversal wins for compilers
- How production compilers do it
- IR generation as a traversal

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

# Three representations

## Imperative \hfill Object-oriented \hfill Functional \centering

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

\small arena-allocated in practice
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

\small GC
::::
:::: {.column width=31%}

```ocaml
type expr =
  | Int of int64
  | Var of string
  | Add of expr * expr
  | Mul of expr * expr
```

\vspace{1em}

\centering
$\Longrightarrow$ \cemph{ADT}

\small GC, immutable

::::
:::

\vspace{0.3em}
\centering
All three encode the same tree. Nothing here decides
the traversal style yet

# Where does the operation live?

## Inside the nodes, or outside the tree \centering

```{=latex}
\lstset{style=small}
```

::: columns
:::: {.column width=48%}

\cemph{Internal: methods on nodes}

```java
record Add(Expr l, Expr r)
    implements Expr {

  long eval(Env env) {
    return l.eval(env)
         + r.eval(env);
  }
}
// eval() also in IntLit, Var, Mul
```
- Every node class carries its copy
  of the operation

::::
:::: {.column width=48%}

\cemphp{External: functions over the tree}

```java
static long eval(Expr e, Env env) {
  return switch (e) {
    case IntLit i -> i.value();
    case Var v    -> env.get(v.name());
    case Add a -> eval(a.l(), env)
                + eval(a.r(), env);
    case Mul m -> eval(m.l(), env)
                * eval(m.r(), env);
  };
}
```

- One place for the whole operation

::::
:::

\vspace{0.5em}
\centering
Two different axes. The language decides
how painful each encoding is

# External traversal in C: switch

## Needs a tag in the representation \centering

```{=latex}
\lstset{style=small}
```

::: columns
:::: {.column width=50%}

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

::::
:::: {.column width=46%}

- Dispatch on the \cemph{tag field}:
  the representation must carry one
- The whole operation is one function:
  new operations never touch the node struct
- \cemphp{No exhaustiveness checking}: forget a
  case and the compiler stays silent.
  This is discipline, not safety
- C requires it; Zig's tagged `switch` does
  check

::::
:::

# External traversal in Java: visitor

## External dispatch, hand-rolled for class hierarchies \centering

```{=latex}
\lstset{style=small}
```

::: columns
:::: {.column width=50%}

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

::::
:::: {.column width=46%}

- Java has no sum types and no pattern
  match (pre-21): the visitor
  \cemph{simulates} one
- `accept()` is a tag in disguise:
  double dispatch routes to the
  right `visitXxx`
- `R` type parameter: one visitor
  interface per result type
- No compiler check for coverage:
  a missing `visitXxx` is a runtime
  `NullPointerException`

::::
:::

# External traversal in Scala: match

## Sealed hierarchies make it safe \centering

```{=latex}
\lstset{style=small}
```

::: columns
:::: {.column width=50%}

```scala
sealed trait Expr
case class IntLit(value: Long)
  extends Expr
case class Var(name: String)
  extends Expr
case class Add(l: Expr, r: Expr)
  extends Expr

def eval(e: Expr): Long =
  e match
    case IntLit(v) => v
    case Var(x)    => env(x)
    case Add(l, r) =>
      eval(l) + eval(r)
```

::::
:::: {.column width=46%}

- `sealed` hierarchy + `match` =
  ADT-style external dispatch
- The compiler checks
  \cemph{exhaustiveness}: forgetting a
  case is a compile error
- \cemph{No `accept()` boilerplate}, no
  visitor interface, no `R`
  parameter
- The same idea OCaml's `match`
  gives over variants, here over
  a class hierarchy

::::
:::

# Convergence

## Modern OO languages adopt external dispatch \centering

::: columns
:::: {.column width=55%}

- Java 21: sealed interfaces +
  pattern `switch`: the visitor's
  job, done by the language

```java
static long eval(Expr e) {
  return switch (e) {
    case IntLit i -> i.value();
    case Add a -> eval(a.l())
                + eval(a.r());
    ...
  };
}
```

- Scala, Kotlin, Swift: pattern
  matching over sealed types is
  idiomatic
- The visitor remains the encoding
  for older Java code bases and
  the standard library

::::
:::: {.column width=42%}

```{=latex}
\begin{minipage}[c][.5\textheight][c]{\linewidth}
\centering
```

\vspace{2em}

The visitor is not a rival mechanism.
It is what external dispatch looks like
when the language does not provide it

\vspace{1em}

Modern languages converge on
\cemph{match}: external traversal
becomes the default

```{=latex}
\end{minipage}
```

::::
:::

# Internal vs external

## The trade-off table \centering

::: columns
:::: {.column width=48%}

\vspace{0.5em}

\small

\begin{tabular}{lcc}
\hline
 & \cemph{add op} & \cemphp{add kind} \\
\hline
internal (methods) & painful & easy \\
\hline
external (switch/visitor/match) & easy & painful \\
\hline
\end{tabular}

\vspace{1em}

- \cemph{Internal}: one new node kind is one new
  class, but the operation is scattered
  across all of them
- \cemph{External}: one new operation is one new
  function, but adding a node kind means
  touching every operation

\vspace{1.5em}

\cemphp{Good for frontend}: compilers run
\emph{many passes} over a \emph{slowly growing}
node set. External traversal pays off

::::
:::: {.column width=48%}

```{=latex}
\begin{minipage}[c][.6\textheight][c]{\linewidth}
\centering
```

Our course, concretely:

- grammars 2--5 add node kinds once each:
  `if`, `while`, functions, types
- every stage re-walks the whole tree:
  codegen now, semantic checks later
- passes outnumber node-kind changes by far

\vspace{1.5em}

The honest counterpoint: application code
where kinds churn faster than operations
is fine with internal dispatch

```{=latex}
\end{minipage}
```

::::
:::

# State and context

## Where the traversal keeps its data \centering

```{=latex}
\lstset{style=small}
```

::: columns
:::: {.column width=48%}

\cemph{Visitor: fields on the object}

```java
class EmitVisitor
    implements Visitor<Value> {
  StringBuilder out;
  SymbolTable scopes;
  Deque<LoopCtx> loops;
  // push/pop around loops

  Value visitAdd(Add e) {
    return builder.add(
      e.l().accept(this),
      e.r().accept(this));
  }
}
```

::::
:::: {.column width=48%}

\cemphp{Match: explicit parameters}

```scala
def emit(e: Expr)(
  out: StringBuilder,
  scopes: SymbolTable,
  loops: List[LoopCtx]
): Value =
  e match
    case Add(l, r) =>
      emit(l)(out, scopes, loops)
      emit(r)(out, scopes, loops)
    ...
```

- Same information, different carrier:
  object fields vs a threaded
  environment argument

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

- CPython: `A_Expr`, op enums
- GCC: `tree_code` over `union tree_node`
- rustc: `enum ExprKind`
- Go: `ir.Op` over a node struct
- LLVM SelectionDAG: `ISD::NodeType`
- Zig: `std.zig.Ast`, tag per node

::::
:::: {.column width=31%}

\cemph{ADTs}

- GHC: `HsExpr` per pass
- OCaml compiler: `Parsetree`
- Scala 3: `Tree` ADT
- F\#: `SynExpr`
- Elm: `Expr`

::::
:::: {.column width=31%}

\cemphp{Class hierarchies}

- Clang: `Stmt`/`Expr` hierarchy
- Swift: `Syntax` protocol tree
- Roslyn: green/red trees
- javac: `JCTree` subclasses
- V8: `AstNode` subclasses

::::
:::

\vspace{1em}
\centering
Whatever the representation, the traversals
on top are external: switch, visitor, or match

# What real compilers do

## Deep dives \centering

::: columns
:::: {.column width=31%}

```{=latex}
\begin{minipage}[c][.55\textheight][c]{\linewidth}
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
\begin{minipage}[c][.55\textheight][c]{\linewidth}
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
\begin{minipage}[c][.55\textheight][c]{\linewidth}
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

- Traversal: `StmtVisitor`, the
  visitor pattern over a class
  hierarchy, state in the visitor
- `Stmt`/`Expr`: about a hundred node
  classes, one per syntactic form
- Every node carries a kind tag: cheap
  `isa`/`dyn_cast` without RTTI
- Uniform child storage: `BinaryOperator`
  keeps `Stmt *SubExprs[2]`: children
  typed `Stmt*`, not dedicated fields
- All nodes allocated in the `ASTContext`
  arena; freed once, when the translation
  unit is done

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

- Traversal: `match` on the variant.
  External dispatch, exhaustiveness
  checked by the compiler
- `enum ExprKind`: about a hundred
  variants, one per syntactic form
- Children are `Box<Expr>` and
  `ThinVec<Box<Expr>>`, boxed since
  enum variants must have one size
- Per-phase arenas: the AST is built,
  used, and dropped together
- AST is only the first tree: lowered to
  HIR, then to MIR, each tree much
  smaller than the last

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

- Traversal: plain `match`, one walk
  per compiler pass
- One ADT per syntactic category:
  `HsExpr`, `HsPat`, `HsType`, \dots
- The ADT is parameterized by the
  \cemph{compiler pass}: `GhcPs` (parsed),
  `GhcRn` (renamed), `GhcTc` (typechecked)
- Type families attach per-phase payloads:
  after renaming a binary application
  records its \cemph{fixity}; after
  typechecking the same variant cannot
  appear at all
- Illegal tree states do not typecheck

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
pass, and one variant is \cemph{gone} after
typechecking

\vspace{0.8em}

\qrcode[height=2.2cm]{https://github.com/ghc/ghc/blob/master/compiler/GHC/Hs/Expr.hs}

[compiler/GHC/Hs/Expr.hs]{.small}

::::
:::

# IR generation is a traversal

## Expressions produce values, statements produce effects \centering

::: columns
:::: {.column width=42%}

- \cemph{Name resolution}, \cemph{type checking},
  \cemph{constant folding}: each a traversal
- \cemph{IR generation}: one more walk over
  the same tree

\vspace{1.5em}

- Expressions produce \cemph{values}
- Statements produce \cemph{effects}:
  `x = ...` emits a `store`
- `alloca` reserves a stack slot per
  variable; `load`/`store` move values
- No registers are assigned by us:
  LLVM handles register allocation

::::
:::: {.column width=50%}

`x = a + b;`

\vspace{0.5em}

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

# IR generation via switch

## The traversal appends IR text \centering

```{=latex}
\lstset{style=small}
```

::: columns
:::: {.column width=50%}

```c
/* emit(e) appends IR lines to the
   function body, returns the name
   of the result temporary */
const char *emit(struct expr *e) {
  switch (e->kind) {
  case EXPR_VAR:
    return tmp("load i64, ptr %%%s",
               e->var_name);
  case EXPR_ADD: {
    const char *l = emit(e->l);
    const char *r = emit(e->r);
    return tmp("add i64 %s, %s",
               l, r);
  }
  }
}
```

::::
:::: {.column width=46%}

- `tmp(...)` allocates the next
  temporary `%n` and appends the line
- The recursion order is the
  \cemph{instruction order}:
  operands first, `add` after
- Exactly the IR from the earlier
  slide
- External dispatch again: one
  function, switch on the tag

::::
:::

# IR generation via visitor

## The visitor object carries the output \centering

```{=latex}
\lstset{style=small}
```

::: columns
:::: {.column width=50%}

```java
class EmitVisitor
    implements Visitor<String> {
  StringBuilder out; // IR text

  String visitVar(Var e) {
    return line(out,
      "load i64, ptr %" + e.name());
  }

  String visitAdd(Add e) {
    var l = e.l().accept(this);
    var r = e.r().accept(this);
    return line(out,
      "add i64 " + l + ", " + r);
  }
}
```

::::
:::: {.column width=46%}

- Same traversal; the dispatch is
  `accept()` instead of `switch`
- The output buffer, symbol table,
  builder, all live in the visitor
  object
- `accept(this)` passes the visitor
  down: children reuse the same
  context

::::
:::

# IR generation via match

## Same walk, pattern-matching syntax \centering

```{=latex}
\lstset{style=small}
```

::: columns
:::: {.column width=50%}

```scala
def emit(e: Expr): String =
  e match
    case Var(x) =>
      line("load i64, ptr %" + x)
    case Add(l, r) =>
      val a = emit(l)
      val b = emit(r)
      line(s"add i64 $a, $b")
    case Mul(l, r) =>
      val a = emit(l)
      val b = emit(r)
      line(s"mul i64 $a, $b")
```

::::
:::: {.column width=46%}

- Exhaustiveness checked: a new
  node kind breaks every emitter
  until handled
- Context (output buffer, scopes,
  loop stack) is threaded through
  parameters, or wrapped in a
  class, at which point it is a
  visitor again

\vspace{1em}

- \cemphp{Good for frontend}: one walk,
  one place per operation

::::
:::

# LLVM: C API and text form

## One instruction, two notations \centering

::: columns
:::: {.column width=50%}

- Our pseudo-emit writes IR text
  directly; the C API builds the same
  instructions as objects

```c
/* C API */
LLVMValueRef L = LLVMBuildLoad2(
    Builder, I64, Slot, "");
LLVMValueRef S = LLVMBuildAdd(
    Builder, L, R, "tmp");
```

```llvm
; the same instructions, text form
%1 = load i64, ptr %a
%tmp = add i64 %1, %2
```

- \cemph{Builder} = insertion point: where
  new instructions are appended
- `%n` = SSA temporaries, one per
  instruction result
- `alloca` / `load` / `store` / `br`
  map one to one

::::
:::: {.column width=42%}

```{=latex}
\begin{minipage}[c][.55\textheight][c]{\linewidth}
\centering
```

\vspace{1em}

\qrcode[height=3.2cm]{https://llvm.org/docs/tutorial/}

\vspace{0.5em}

[LLVM Tutorial: My First Language Frontend]{.small}

```{=latex}
\end{minipage}
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

## The targets live in the traversal, not in the tree \centering

::: columns
:::: {.column width=45%}

- `break` / `continue` are just jumps,
  but to blocks of the \cemph{enclosing loop}
- The node itself does not know its target
- The emitter keeps a stack of
  `(break target, continue target)` pairs,
  pushed by `while` / `for`, popped after

\vspace{1.5em}

- Same idea as symbol tables:
  the traversal carries context that
  the AST does not contain
- Visitor: fields on the object.
  Match: explicit parameters

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
