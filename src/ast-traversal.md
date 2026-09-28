---
title: AST design
subtitle: Compiler implementation
---

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
    base/.style={minimum width={2em},minimum height={2em},inner sep=0.8em,outer sep=auto},
    n/.style={base,draw,solid},
    block/.style={n,circle},
    every matrix/.style={row sep=2em,column sep=1.5em,ampersand replacement=\&,every node/.style={block}},
  ]

  \matrix {
  \& \& \node [block] (mul) {$\cdot$}; \& \\
  \& \node [block] (add) {$+$}; \& \& \node [block] (c) {$c$}; \\
  \node [block] (a) {$a$}; \& \& \node [block] (b) {$b$}; \\
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

# Representations

```{=latex}
\lstset{style=small}
```

::: columns
:::: {.column width=28%}

## Tagged union \centering

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

::::
:::: {.column width=33%}

## Class hierarchy \centering

```scala
sealed trait Expr
case class IntLit(value: Long)
  extends Expr
case class Var(name: String)
  extends Expr
case class Add(l: Expr, r: Expr)
  extends Expr
case class Mul(l: Expr, r: Expr)
  extends Expr
```

::::
:::: {.column width=31%}

## Abstract Data Type (ADT) \centering

```scala
enum Expr:
  case IntLit(value: Long)
  case Var(name: String)
  case Add(l: Expr, r: Expr)
  case Mul(l: Expr, r: Expr)
```

::::
:::

\vspace{0.3em}
\small

::: columns
:::: {.column width=28%}

\centering

arena-allocated

::::
:::: {.column width=33%}

\centering

GC or arena-allocated

::::
:::: {.column width=31%}

\centering

GC, immutable

::::
:::

# Representation of passes

```{=latex}
\lstset{style=small}
```

::: columns
:::: {.column width=46%}

## Internal: methods on nodes \centering

```scala
sealed trait Expr:
  def eval(env: Env): Long

case class Add(l, r) extends Expr
  def eval(env: Env): Long =
    l.eval(env) + r.eval(env)
```

::::
:::: {.column width=52%}

## External: functions over the tree \centering

```scala
def eval(e: Expr, env: Env): Long = e match
  case IntLit(v) => v
  case Var(x)    => env(x)
  case Add(l, r) => eval(l, env) + eval(r, env)
  case Mul(l, r) => eval(l, env) * eval(r, env)
```

::::
:::

# External traversal {.fragile}

```{=latex}
\lstset{style=small}
```

. . .

::: columns
:::: {.column width=48%}

::::: block

## Switch \centering

- Dispatch on the \cemph{tag field}
- No exhaustiveness checks
- State needs explicit params

:::::

```{=latex}
\begin{uncoverenv}<3->
```
::::: block

## Match \centering

- Supported in many modern languages
- Exhaustiveness checks
- State needs explicit params

:::::

```{=latex}
\end{uncoverenv}
```

```{=latex}
\begin{uncoverenv}<4->
```

::::: block

## Visitor \centering

- Object-oriented alternative
- No exhaustiveness checks
- Visitor carries state

:::::

```{=latex}
\end{uncoverenv}
```

::::
:::: {.column width=50%}

##

```{=latex}
\begin{onlyenv}<2>
```

::::: block

```c
int64_t eval(const struct expr *e) {
  switch (e->kind) {
    case EXPR_INT:
      return e->int_val;
    case EXPR_VAR:
      return lookup(name);
    case EXPR_ADD:
      return eval(e->l) + eval(e->r);
    case EXPR_MUL:
      return eval(e->l) * eval(e->r);
  }
}
```

:::::

```{=latex}
\end{onlyenv}
```

```{=latex}
\begin{onlyenv}<3>
```

::::: block

```scala
sealed trait Expr
case class IntLit(value: Long) extends Expr
case class Var(name: String) extends Expr
case class Add(l: Expr, r: Expr) extends Expr
case class Mul(l: Expr, r: Expr) extends Expr

def eval(e: Expr): Long = e match
  case IntLit(v) => v
  case Var(x)    => env(x)
  case Add(l, r) => eval(l) + eval(r)
  case Mul(l, r) => eval(l) * eval(r)
```

:::::

```{=latex}
\end{onlyenv}
```

```{=latex}
\begin{onlyenv}<4>
```

::::: block

```scala
trait Visitor[R] {
  def visitInt(e: IntLit): R
  def visitVar(e: Var): R
  def visitAdd(e: Add): R
  def visitMul(e: Mul): R
}

case class Add(l: Expr, r: Expr) extends Expr:
  def accept(v: Visitor[R]): R =
    v.visitAdd(this)
```

:::::

```{=latex}
\end{onlyenv}
```

::::
:::

# Internal vs external {.fragile}

::: columns
:::: {.column width=48%}

## Trade-offs \centering

- \cemph{Internal}: one new node kind is one new
  class, but the pass logic is scattered
  across all of them
- \cemph{External}: one new pass is one new
  function/class, but adding a node kind means
  touching every pass

\vspace{1.5em}

\cemphp{Good for frontend}: compilers run
\emph{many passes} over a \emph{slowly growing}
node set. External traversal pays off

::::
:::: {.column width=48%}

## 

|          | Add pass | Add node |
|:--------:|:--------:|:--------:|
| Internal | painful  | easy     |
| External | easy     | painful  |

::::
:::

# State and context {.fragile}

```{=latex}
\lstset{style=small}
```

::: columns
:::: {.column width=46%}

## Visitor: fields on the object \centering

```scala
class EmitVisitor(
    val out: StringBuilder,
    var scopes: SymbolTable,
    var loops: List[LoopCtx]
) extends Visitor[Value]:

  def visitAdd(e: Add): Value =
    builder.add(
      e.l.accept(this),
      e.r.accept(this))
```

::::
:::: {.column width=46%}

## Match/switch: explicit parameters \centering

```scala
def emit(e: Expr)(
  out: StringBuilder,
  scopes: SymbolTable,
  loops: List[LoopCtx]
): Value = e match

  case Add(l, r) =>
    emit(l)(out, scopes, loops)
    emit(r)(out, scopes, loops)
```

::::
:::

# Real compilers

```{=latex}
\lstset{style=small}
```

::: columns
:::: {.column width=31%}

## Tagged union \centering

- GCC: `tree_code` over
  `union tree_node`
- CPython: op enums over node
  structs (classic form)
- Go: `ir.Op` over a node struct
- Zig: `std.zig.Ast`, tag per node

::::
:::: {.column width=31%}

## Class hierarchy \centering

- scalac: `Trees.scala`, `Tree`
  subclasses
- Clang: `Stmt`/`Expr` hierarchy
- javac: `JCTree` subclasses
- V8: `AstNode` subclasses

::::
:::: {.column width=31%}

## ADT \centering

- Scala 3 (dotty): the same `Tree`
  as `case class` ADT
- OCaml compiler: `Parsetree`
- F\#: `SynExpr`
- Elm: `Expr`

::::
:::

\vspace{1em}

## Traversal is always external: switch, visitor, or match \centering

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

<!-- QR candidate (teacher decides whether/where to include):
\qrcode[height=2.2cm]{https://github.com/llvm/llvm-project/blob/main/clang/include/clang/AST/Expr.h}

[clang/AST/Expr.h]{.small}
-->

::::
:::

# GCC

## tagged union + arena \centering

```{=latex}
\lstset{style=small}
```

::: columns
:::: {.column width=48%}

- One node type: `union tree_node`,
  the `tree` is a pointer to it
- `enum tree_code`: over two hundred
  codes, one per form
  (`INTEGER_CST`, `PLUS_EXPR`, ...)
- Traversal: `switch` on the code,
  guided by `tree_code_class`
- Nodes live in the GC-managed
  arena (`GGC`), collected a whole
  generation at once
- The same `tree` from parser to
  code generation

::::
:::: {.column width=48%}

```{=latex}
\centering
```

```c
/* tree.def: one line per code */
DEFTREECODE (INTEGER_CST,
  "integer_cst", tcc_constant, 0)
DEFTREECODE (PLUS_EXPR,
  "plus_expr", tcc_binary, 2)

/* tree-core.h */
enum tree_code : unsigned {
#include "all-tree.def" MAX_TREE_CODES
};

/* the node itself */
union tree_node {
  struct tree_base base;
  struct tree_int_cst int_cst;
};
```

::::
:::

# scalac (Scala 3)

## class hierarchy, one tree per pass \centering

```{=latex}
\lstset{style=small}
```

::: columns
:::: {.column width=48%}

- `abstract class Tree[T]`: node
  classes in `Trees.scala`, one per
  form (`Ident`, `Apply`, ...)
- `T` is the pass: `Untyped` from
  the parser, typed after the typer;
  the type lives in the node
- Traversal: `TreeTraverser` /
  `TreeMap` base classes, clients
  override per-node callbacks
- Types are set copy-on-write: a
  tree is reused across passes
- `case class` nodes double as an
  ADT: `match` works on them too

::::
:::: {.column width=48%}

```{=latex}
\centering
```

```scala
abstract class Tree[+T <: Untyped]
  extends Positioned, SrcPos

case class Ident[+T <: Untyped]
  (name: Name) extends RefTree[T]

case class Apply[+T <: Untyped]
  (fun: Tree[T], args: List[Tree[T]])

case class Literal[+T <: Untyped]
  (const: Constant) extends Tree[T]
```

\vspace{0.5em}

\cemph{T} selects the pass: `Untyped`
or the typed tree

::::
:::

# IR generation

::: columns
:::: {.column width=48%}

## AST travelsals

- \cemphp{Name resolution}
- \cemphp{type checking},
- \cemphp{constant folding}
- \cemphp{IR generation}

## IR generation

- Expressions produce \cemph{values}
- Statements produce \cemph{effects}:
  `x = ...` emits a `store`
- `alloca` reserves a stack slot per
  variable; `load`/`store` move values
- No registers are assigned by us:
  LLVM handles register allocation

::::
:::: {.column width=46%}

## `x = a + b;`

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

# IR generation {.fragile}

```{=latex}
\lstset{style=small}
```

. . .

::: columns
:::: {.column width=46%}

::::: block

## Switch \centering

- `tmp(...)` allocates the next
  temporary `%n` and appends the line
- The recursion order is the
  \cemph{instruction order}:
  operands first, `add` after

:::::

```{=latex}
\begin{uncoverenv}<3->
```
::::: block

## Match \centering

- Exhaustiveness checks
- Context (output buffer, scopes,
  loop stack) is threaded through
  parameters

:::::

```{=latex}
\end{uncoverenv}
```

```{=latex}
\begin{uncoverenv}<4->
```

::::: block

## Visitor \centering

- The output buffer, symbol table,
  builder, all live in the visitor
  object
- `accept(this)` passes the visitor
  down: children reuse the same
  context

:::::

```{=latex}
\end{uncoverenv}
```

::::
:::: {.column width=50%}

##

```{=latex}
\begin{onlyenv}<2>
```

::::: block

```c
/* returns the name of the result var */
const char *emit(struct expr *e) {
  switch (e->kind) {

    case EXPR_VAR:
      return tmp("load i64, ptr %%%s",
                            e->var_name);

    case EXPR_ADD: {
      const char *l = emit(e->l);
      const char *r = emit(e->r);
      return tmp("add i64 %s, %s", l, r);
    }
  }
}
```

:::::

```{=latex}
\end{onlyenv}
```

```{=latex}
\begin{onlyenv}<3>
```

::::: block

```scala
def emit(e: Expr): String = e match

  case Var(x) =>
    line(s"load i64, ptr %$x")

  case Add(l, r) =>
    val a = emit(l)
    val b = emit(r)
    line(s"add i64 $a, $b")

  case Mul(l, r) =>
    val a = emit(l)
    val b = emit(r)
    line(s"mul i64 $a, $b")
```

:::::

```{=latex}
\end{onlyenv}
```

```{=latex}
\begin{onlyenv}<4>
```

::::: block

```scala
class EmitVisitor(
  val out: StringBuilder
) extends Visitor[String]:

  def visitVar(e: Var): String =
    line(out, s"load i64, ptr %${e.name}")

  def visitAdd(e: Add): String = {
    val l = e.l.accept(this)
    val r = e.r.accept(this)
    line(out, s"add i64 $l, $r")
  }
```

:::::

```{=latex}
\end{onlyenv}
```

::::
:::

# LLVM C API vs text form

::: columns
:::: {.column width=48%}

## LLVM C API \centering

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

::::
:::: {.column width=48%}

## Text \centering

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
:::

# Control flow

## if \centering

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
\begin{minipage}[c][.7\textheight][c]{\linewidth}
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

# Control flow

## while \centering

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
\begin{minipage}[c][.7\textheight][c]{\linewidth}
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

# Control flow

## break and continue \centering

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
- Visitor: fields on the object
- Match: explicit parameters

::::
:::: {.column width=45%}

```{=latex}
\begin{minipage}[c][.7\textheight][c]{\linewidth}
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
  \draw[->,dashed] (body) to[bend left=15] node[above left] {\cemphp{continue}} (cond);
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
