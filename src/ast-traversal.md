---
title: "ASTs & traversal design"
---

# The plan for today

##

::: columns
:::: {.column width=55%}

- One AST, three language families
  - C/Zig --- tagged unions
  - Java/Scala --- class hierarchies
  - OCaml --- variants
- How production compilers do it
  - Clang, Roslyn, the OCaml compiler itself
- Traversal design: \cemph{the expression problem}
  - visitor vs switch vs match vs fold

::::
:::: {.column width=40%}

```{=latex}
\begin{minipage}[c][.5\textheight][c]{\linewidth}
\centering
```

- Then: \cemphp{codegen is just another traversal}
  - expressions $\to$ values
  - statements $\to$ effects
  - `alloca` / load / store

```{=latex}
\end{minipage}
```

::::
:::

# One AST, three shapes

##

::: columns
:::: {.column width=48%}

The same little language:

$$e \;=\; n \;\mid\; x \;\mid\; e_1 + e_2 \;\mid\; e_1 \cdot e_2$$

The tree for `a + b * c` is the same in every language.

What differs is \cemph{how the type system expresses it}:

- three idioms for sum types ---
  three sets of trade-offs

::::
:::: {.column width=48%}

```{=latex}
\begin{minipage}[c][.4\textheight][c]{\linewidth}
\centering
\begin{tikzpicture}[
    ->,>=latex,
    every node/.style={font=\footnotesize},
    n/.style={draw,rounded corners,minimum width=3.2em,minimum height=1.6em},
  ]
  \node[n] (add) {$+$};
  \node[n,below left=1.2em and 0.8em of add] (a) {$a$};
  \node[n,below right=1.2em and 0.8em of add] (mul) {$\cdot$};
  \node[n,below left=1.2em and 0.2em of mul] (b) {$b$};
  \node[n,below right=1.2em and 0.2em of mul] (c) {$c$};
  \draw (add) -- (a);
  \draw (add) -- (mul);
  \draw (mul) -- (b);
  \draw (mul) -- (c);
\end{tikzpicture}
```

```{=latex}
\end{minipage}
```

::::
:::

# C/Zig: tagged union + switch

##

```{=latex}
\lstset{style=small}
```

::: columns
:::: {.column width=58%}

```c
enum expr_kind { EXPR_INT, EXPR_VAR,
                 EXPR_ADD, EXPR_MUL };

struct expr {
    enum expr_kind kind;
    union {
        int64_t  int_val;
        char    *var_name;
        struct { struct expr *l, *r; };
    };
};

struct expr *add(struct expr *l,
                 struct expr *r);
```

::::
:::: {.column width=40%}

- data is \cemph{one struct with a tag}
- Zig: `union(enum) { int: i64, ... }`
  - tag + payload handled by the language
- memory: manual (`malloc`/`free` or arena)
- **who has this shape at home?**

\vspace{1em}
Zig `switch` is exhaustive ---
the compiler keeps the checklist for you

::::
:::

# Java/Scala: class hierarchy

##

::: columns
:::: {.column width=55%}

```java
sealed interface Expr permits
    IntLit, Var, Add, Mul {}

record IntLit(long value)
        implements Expr {}
record Var(String name)
        implements Expr {}
record Add(Expr left, Expr right)
        implements Expr {}
record Mul(Expr left, Expr right)
        implements Expr {}
```

::::
:::: {.column width=40%}

- the type hierarchy \cemph{is} the schema
- Scala:

```scala
sealed trait Expr
case class Add(l: Expr, r: Expr)
      extends Expr
```

- modern Java: records + pattern
  matching in `switch`
- **who has this shape at home?**

::::
:::

# OCaml: variant + pattern match

##

::: columns
:::: {.column width=55%}

```ocaml
type expr =
  | Int of int64
  | Var of string
  | Add of expr * expr
  | Mul of expr * expr

let e = Add (Var "a",
          Mul (Var "b", Var "c"))
```

::::
:::: {.column width=40%}

- the whole AST: \cemphp{one line}
- `match` is exhaustive \cemph{by default}
- memory: GC --- don't think about it
- this is the "flat enum" style
  rustc uses internally

\vspace{1em}
**Who has this shape at home?**

::::
:::

# Same tree, three shapes

##

::: columns
:::: {.column width=100%}

\begin{center}
\begin{tabular}{lll}
\hline
 & representation & memory \\
\hline
C     & tagged struct + union & manual / arena \\
Zig   & tagged union          & arenas idiomatic \\
Java/Scala & class hierarchy  & GC \\
OCaml & variant               & GC \\
\hline
\end{tabular}
\end{center}

\vspace{1em}
\cemph{union-of-variants (data-first)} vs \cemphp{class-hierarchy (type-first)}

\vspace{0.5em}
Your language pushed you into a corner --- now you own that corner's trade-offs.

::::
:::

# Production compilers

##

::: columns
:::: {.column width=55%}

\cemphp{Clang} (C++)

- deep class hierarchy: `Stmt` $\to$ `Expr` $\to$ $\dots$
- inheritance = the poor man's sum type
- every node carries a `Kind` tag (\cemph{classof})
- uniform `children()` iteration
- cost: macro-generated boilerplate

\vspace{0.8em}
\cemphp{OCaml compiler} (guess)

- its own `parsetree` is a giant
  OCaml variant --- dogfooding

::::
:::: {.column width=42%}

\cemphp{Roslyn} (C\#) --- red-green trees

- \cemph{green}: compact, immutable, no positions --- sharing everywhere
- \cemph{red}: positions + parent links, mostly cached views
- why: IDE undo, cheap snapshots
- our ast.json goldens (with line/column)
  = "red tree" data

::::
:::

# Exercise: grammar 2 lands

##

::: columns
:::: {.column width=50%}

```
if (c) { s1 } else { s2 }
while (c) { s }
```

For each of the three shapes:

- what gets added?
- what gets \cemph{generalized}?
- does your schema survive \cemphp{additively}?

::::
:::: {.column width=45%}

- new variants: `If`, `While`
- new \cemph{split}: statements vs
  expressions (grammar 1 was
  almost all expressions)
- `break`: leaf statement ---
  but wait until codegen $\dots$

\vspace{1em}
additive change vs
\cemphp{schema-breaking change} ---
which one did your design admit?

::::
:::

# The expression problem

##

::: columns
:::: {.column width=100%}

\begin{center}
\begin{tabular}{lcc}
\hline
 & add \cemph{operation} & add \cemph{node kind} \\
\hline
visitor (Java/Scala)  & easy & painful \\
switch on tag (C)     & painful$^{*}$ & easy \\
tagged union switch (Zig) & painful$^{*}$ & easy \cemphp{+ checklist} \\
ADT + match (OCaml)   & painful$^{*}$ & easy \cemphp{+ checklist} \\
fold / catamorphism   & easy & painful-ish \\
\hline
\end{tabular}
\end{center}

\vspace{0.6em}
{\footnotesize $^{*}$unless your language checks exhaustiveness --- then it's the compiler's to-do list}

\vspace{0.8em}
This semester: node kinds keep coming (g2--g5).

Next semester: \cemphp{operations} keep coming (passes).

Which axis did your choice make painful?

::::
:::

# Visitor: double dispatch

##

::: columns
:::: {.column width=55%}

```java
interface ExprVisitor<R> {
    R visitInt(IntLit e);
    R visitVar(Var e);
    R visitAdd(Add e);
    R visitMul(Mul e);
}

record Add(Expr l, Expr r)
        implements Expr {
    R accept(ExprVisitor<R> v) {
        return v.visitAdd(this);
    }
}
```

::::
:::: {.column width=40%}

- each node \cemph{knows} its type ---
  and calls back
- adding an \cemph{operation} =
  new visitor, existing AST
- adding a \cemph{node kind} =
  touch the interface +
  \cemphp{every visitor}
- the classic pattern in
  Java-land compilers

\vspace{0.8em}
Where it's fine: stable node set,
many operations

::::
:::

# Switch on tag: C vs Zig

##

```{=latex}
\lstset{style=small}
```

::: columns
:::: {.column width=48%}

```c
/* C: silent if you forget a case */
int64_t eval(const struct expr *e,
             const struct env *env) {
    switch (e->kind) {
    case EXPR_INT:
        return e->int_val;
    case EXPR_VAR:
        return lookup(env, e->var_name);
    case EXPR_ADD:
        return eval(e->l, env)
             + eval(e->r, env);
    case EXPR_MUL:
        return eval(e->l, env)
             * eval(e->r, env);
    }
    return -1; /* ...and this */
}
```

::::
:::: {.column width=49%}

```zig
// Zig: the compiler IS the checklist
fn eval(e: Expr, env: *Env) !i64 {
    return switch (e) {
        .int  => |v| v,
        .var  => |n| env.get(n),
        .add  => |p| try eval(p.l, env)
                   + try eval(p.r, env),
        .mul  => |p| try eval(p.l, env)
                   * try eval(p.r, env),
    };
}
```

\vspace{0.8em}
add `.div` to the union $\Rightarrow$
\cemphp{compile error} here ---
a to-do list you can't ignore

::::
:::

# OCaml: match, and the 10-line evaluator

##

::: columns
:::: {.column width=55%}

```ocaml
let rec eval env = function
  | Int n -> n
  | Var x -> Env.find x env
  | Add (l, r) ->
      Int64.add (eval env l) (eval env r)
  | Mul (l, r) ->
      Int64.mul (eval env l) (eval env r)
```

\vspace{0.6em}
{\footnotesize exhaustiveness checked ---
forgot a case? compile error}

::::
:::: {.column width=40%}

- recursion + match: the whole
  interpreter
- generalization: \cemph{fold}
  (catamorphism) --- define the
  recursion scheme once over the
  shape; operations become algebras
- ambitious corner: look up
  "fixpoints of functors" if curious

\vspace{0.8em}
Generic walker + callbacks
(`RecursiveASTVisitor` in clang):
same idea for OO languages ---
one walker, all operations

::::
:::

# Honest closing of part 1

##

- for five grammars, \cemph{any consistent choice works}
- the skill is \cemphp{knowing the trade-off}, not picking the winner
- next semester you'd add operations (passes) ---
  today's choice decides how much that hurts
- discussion: which corner are you in, and what hurts first?

# Codegen is just another traversal

##

::: columns
:::: {.column width=55%}

`var x = a + b * c; return x;`

```llvm
%x.slot = alloca i64
%a = load i64, ptr %a.slot
%b = load i64, ptr %b.slot
%c = load i64, ptr %c.slot
%t1 = mul i64 %b, %c
%t2 = add i64 %a, %t1
store i64 %t2, ptr %x.slot
ret i64 %t2
```

\vspace{0.4em}
{\footnotesize same tree, same IR --- traversal does the work}

::::
:::: {.column width=42%}

- expressions: \cemphp{produce values}
  (`Add` returns an LLVM `Value*`)
- statements: \cemph{produce effects}
  (`var x = ...` emits a store,
  returns nothing)
- this split is \cemph{why} decl/expr
  separation exists in your AST
- variables = `alloca` + load/store;
  scope = which alloca is visible ---
  a traversal with an environment

::::
:::

# Codegen, in two of today's styles

##

```{=latex}
\lstset{style=small}
```

::: columns
:::: {.column width=58%}

```c
/* C: one emit function */
LLVMValueRef emit(const struct expr *e,
                  struct ctx *ctx) {
    switch (e->kind) {
    case EXPR_INT:
        return LLVMConstInt(i64, e->int_val, 0);
    case EXPR_ADD:
        return LLVMBuildAdd(b,
                 emit(e->l, ctx),
                 emit(e->r, ctx), "t");
    /* ... */
    }
}
```

::::
:::: {.column width=39%}

```ocaml
(* OCaml: the same traversal *)
let rec emit env = function
  | Int n -> const i64 n
  | Var x -> load (find x env)
  | Add (l, r) -> build_add
      (emit env l) (emit env r)
  | Mul (l, r) -> build_mul
      (emit env l) (emit env r)
```

\vspace{0.8em}
different glue, \cemph{identical IR}

\vspace{0.8em}
\cemphp{No phi functions needed:}
alloca + load/store is fine ---
`opt`'s mem2reg turns it into SSA
(that's next semester's theory)

::::
:::

# What grammar 2 will do to this

##

::: columns
:::: {.column width=50%}

```
if (c) s1 else s2
```

```{=latex}
\begin{minipage}[c][.42\textheight][c]{\linewidth}
\centering
\begin{tikzpicture}[
    ->,>=latex,
    every node/.style={font=\footnotesize,align=left},
    n/.style={draw,rounded corners,minimum width=4.5em,minimum height=1.8em},
  ]
  \node[n] (entry) {entry};
  \node[n,below=1.4em of entry] (then) {then};
  \node[n,below=1.4em of then] (els) {else};
  \node[n,below=1.4em of els] (merge) {merge};
  \draw (entry) -- (then);
  \draw (entry) -- (els);
  \draw (then) -- (merge);
  \draw (els) -- (merge);
\end{tikzpicture}
```

```{=latex}
\end{minipage}
```

::::
:::: {.column width=45%}

- same traversal --- but now it
  \cemph{creates basic blocks} and
  terminates them (`br`)
- `if` produces \cemphp{control}, not values
- `break`/`continue`: leaf nodes in the
  AST --- but the emitter must carry
  "which loop am I inside" context
- alloca for the condition variables,
  `br i1` for the branches --- \cemph{no phi
  functions, this semester is alloca-land}

\vspace{0.6em}
That's your codegen deadline exercise --- two weeks.

::::
:::

# Takeaways

##

::: columns
:::: {.column width=55%}

- one AST, three shapes ---
  language idiom decides, trade-offs transfer
- production compilers scale the same
  ideas (Clang hierarchy, Roslyn
  snapshots, OCaml dogfooding)
- traversal choice = \cemph{picking your
  painful axis}
- codegen is just another traversal ---
  \cemphp{statements vs expressions} is the fork

::::
:::: {.column width=40%}

Homework (voluntary, ungraded):

- add `If`/`While` (and `Break`/`Continue`)
  to your AST, in your style
- write the `emit`-skeleton for `if`:
  entry/then/else/merge blocks,
  alloca style

\vspace{0.8em}
feeds the parser deadline (this week)
and the codegen window (two weeks)

::::
:::
