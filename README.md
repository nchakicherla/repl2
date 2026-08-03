# repl2

repl2 is a REPL for exercising a grammar you define yourself. Point it at a
grammar file, type (or pipe, or `:load`) some input, and it runs it - a
tree-walking interpreter dispatches on the tags your grammar's rules
produce, the same way whether the concrete syntax is C-like or something
else entirely. `:ast`/`:tokens`/`:shapes` are still there to inspect what a
candidate grammar produces without needing execution semantics attached
first - it's a testing ground for designing a scripting language or DSL,
letting you see exactly how a grammar carves up a piece of source, and
then actually run it once you're ready to.

It combines pieces of two earlier, related projects by the same author:
the grammar/tokenizer/parser/AST pipeline is adapted from
`flexible-parser`, with its original bump allocator (`MemPool`) replaced
by `db4`'s arena. See [LICENSE](LICENSE) for the full provenance.

## Scope

**Non-goals (for now):** no VM, no bytecode compiler. The tree-walking
interpreter here is deliberately the simpler thing to get right first - a
reference implementation to validate a bytecode VM against later, by
running the same programs through both and diffing the output, rather
than trusting a from-scratch VM's correctness on faith.

## Capabilities

- **Grammar files are data, not code**: a `.txt` file of `NAME = alt ;`
  productions (conventional EBNF - `,` for sequence, `|` for alternation,
  `[]` optional, `{}` repetition) defines both the token vocabulary
  (`#token`/`#keyword` directives) and the rule tree. Swap `-g` to a
  different file and the same binary parses a different language - no
  recompile. See [src/grammar.h](src/grammar.h) for the exact grammar
  syntax, and [resources/grammar.txt](resources/grammar.txt) /
  [resources/grammar-mini.txt](resources/grammar-mini.txt) for two
  deliberately different example languages.
- **Scanner**: registry-driven, not hand-written - keyword and punctuation
  recognition is built from whatever the grammar file declared, so a
  grammar can introduce tokens the C source has never heard of.
- **Parser**: recursive-descent over the compiled rule tree, with explicit
  guards against pathological grammars - a bracket-nesting depth limit at
  grammar-load time, and a separate rule-reference depth limit at parse
  time (catches left-recursive rules like `A = A ;` and reports it instead
  of recursing forever).
- **REPL**: bracket-balance-aware continuation (an unbalanced `(`/`{`/`[`
  keeps reading), Shift+Enter or a trailing backslash to force a
  continuation on terminals that don't report Shift+Enter, command
  history, and `:load` to run a file in the same session.
- **Memory**: everything is arena-allocated (db4's block-based `Arena`),
  with a default budget of 40-80% of total RAM (override via
  `DB4_MEM_LIMIT_MB`) and a single checked failure path
  ([src/oom.c](src/oom.c)) rather than allocation failures turning into
  undefined behavior.
- **Interpreter**: a tree-walking evaluator ([src/interp.c](src/interp.c))
  ported from flexible-parser's original, switching on the built-in
  `STX_*` tags and pulling children by role rather than fixed position
  (see "On grammar and semantics" below) - variables, arithmetic with
  correct precedence, `if`/`while`/`for`, functions with lexically-scoped
  calls, `break`/`return`/`exit`. [src/object.h](src/object.h) is the
  runtime value representation (nil/int/float/bool/string) and
  [src/env.h](src/env.h) the variable-binding stack, both grammar-agnostic
  and usable independently of the tree-walker - see either header's own
  doc comment.

## Building

```bash
make
```

Produces `bin/repl2`. `make debug` builds an unoptimized, symbol-ful
binary; `make clean` removes build output.

## Using the REPL

```
$ bin/repl2 -g resources/grammar-mini.txt
repl2  grammar: resources/grammar-mini.txt
type :help for commands, Ctrl-D to exit

>>> let x := 5;
>>> x + 1
6
>>> :quit
```

`let x := 5;` is a statement (it ends in `;`, wrapped in the grammar's own
statement rule) and runs silently; `x + 1` is a bare expression (no `;`,
matched directly) and its value is printed automatically - the same
`STX_EXPR`/`STX_FNCALL`/... check either grammar's own interpreter-facing
tags would use, regardless of concrete syntax.

| Command | Effect |
|---|---|
| `:help` / `:h` | Show the command list |
| `:quit` / `:q` (also Ctrl-D) | Leave the REPL |
| `:ast` | Toggle printing the syntax tree for each entry |
| `:tokens` | Toggle printing the token stream for each entry |
| `:shapes` | Toggle checking each entry's tree against the built-in tags' structural requirements (see [src/shape.h](src/shape.h)) |
| `:rules` | List the rules the loaded grammar defines |
| `:load <file>` | Read, parse, and run a source file in this session |
| `:reset` | Discard all variables and functions |

Any other input is tokenized against the loaded grammar, matched against
its rules - the grammar's own start rule first, then every other rule it
defines, so one entry can hold several statements (a Shift+Enter block
usually does) - and then run: variables and functions declared at the
prompt stay in scope for later entries in the same session.

## Running a script

```bash
bin/repl2 -g resources/grammar.txt -s resources/script.tl
```

Parses the file once and runs it (or reports a scan/parse error and exits
non-zero) instead of starting the REPL. Useful flags:

```
usage: repl2 [options]
  -g <file>   grammar file      (default ./resources/grammar.txt)
  -s <file>   parse and run this source file, instead of starting
              the repl
  --tokens    print the token stream (only useful with -s)
  --ast       print the syntax tree (only useful with -s)
  --check-shapes  check the parsed tree against the built-in tags'
                  structural requirements (only useful with -s)
  --parse-only  parse (and print --tokens/--ast/--check-shapes, if
                given) but don't run it (only useful with -s)
  --dump-grammar <file>  write the compiled rule trees to a file
  -h  --help  this message
```

`--parse-only` is what to reach for while you're still designing a
grammar and don't want a half-finished program's side effects (or a
runtime error from a construct you haven't wired execution up for yet) -
it's the direct equivalent of what `-s` used to do here before an
interpreter existed at all.

## On grammar and semantics

The interpreter ([src/interp.c](src/interp.c)) switches on built-in syntax
tags (`STX_IF`, `STX_WHILE`, ...) and pulls children by role rather than
fixed position, so reusing a tag for a rule that matches its intent runs
correctly without any change to interp.c, even across grammars with
completely different concrete syntax - `resources/grammar.txt` and
`resources/grammar-mini.txt` are genuinely different languages (different
keywords, different punctuation, parens vs. no parens on conditions) and
both run through the same unmodified interpreter. Minting a new rule
name, or reusing an existing tag for something structurally different,
still parses and prints in the AST fine but carries no built-in
meaning - there's no enforcement of that convention at the grammar layer,
by design; giving new syntax real semantics means adding a case to
interp.c yourself.

[src/shape.h](src/shape.h) (`:shapes` in the REPL, `--check-shapes` with
`-s`) checks a parsed tree against what a tag like `STX_WHILE` or
`STX_FNDEF` structurally needs for interp.c's own tree-navigation to find
what it's looking for - e.g. a rule tagged `STX_WHILE` with no named
children at all, so there could never be a condition to test. It
deliberately can't catch everything: `STX_IF` and `STX_WHILE` both just
need one condition and one body, so tagging an if-shaped rule `STX_WHILE`
by mistake produces an identically-shaped tree - nothing structural
distinguishes them, and interp.c will happily *loop* on what reads like an
`if`. That's a naming/intent mistake, not a shape mistake, and no
structural check can catch it - only running the example and noticing the
behavior is wrong will.

## License

MIT, plus a credit to Robert Nystrom for `scanner.c`'s heritage
(Crafting Interpreters) - see [LICENSE](LICENSE) for full provenance, and
[THIRD_PARTY_LICENSES](THIRD_PARTY_LICENSES) for vendored `linenoise`.
