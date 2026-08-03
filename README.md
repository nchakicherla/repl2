# repl2

repl2 is a REPL for exercising a grammar you define yourself. Point it at a
grammar file, type (or pipe, or `:load`) some input, and it prints the
`SyntaxNode` tree that input produced - nothing more. There's no
interpreter and no execution: it's a testing ground for designing a
scripting language or DSL's *syntax*, letting you see exactly how a
candidate grammar carves up a piece of source before committing to what any
of it should mean.

It combines pieces of two earlier, related projects by the same author:
the grammar/tokenizer/parser/AST pipeline is adapted from
`flexible-parser`, with its original bump allocator (`MemPool`) replaced
by `db4`'s arena. See [LICENSE](LICENSE) for the full provenance.

## Scope

**Non-goals:** no interpreter, no VM, no bytecode, no semantic actions
attached to a grammar rule. Parsing and AST inspection only - depth on
"does this grammar capture the syntax I want" rather than breadth on
"and now make it run."

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
- /STX_INIT
	- TK_LET let
	- /STX_VAR
		- TK_IDENTIFIER x
	- TK_ASSIGN :=
	- /STX_EXPR
		- /STX_NUM
			- TK_NUM 5
	- TK_SEMICOLON ;
>>> :quit
```

| Command | Effect |
|---|---|
| `:help` / `:h` | Show the command list |
| `:quit` / `:q` (also Ctrl-D) | Leave the REPL |
| `:ast` | Toggle printing the syntax tree for each entry (on by default) |
| `:tokens` | Toggle printing the token stream for each entry |
| `:rules` | List the rules the loaded grammar defines |
| `:load <file>` | Read and parse a source file in this session |

Any other input is tokenized against the loaded grammar and matched
against its rules - the grammar's own start rule first, then every other
rule it defines, so one entry can hold several statements (a Shift+Enter
block usually does) and the REPL still works unmodified against a grammar
whose rule names it has never seen before.

## Parsing a script

```bash
bin/repl2 -g resources/grammar.txt -s resources/script.tl
```

Parses the file once and prints its AST (or reports a scan/parse error and
exits non-zero) instead of starting the REPL. Useful flags:

```
usage: repl2 [options]
  -g <file>   grammar file      (default ./resources/grammar.txt)
  -s <file>   parse this source file and print its AST, instead of
              starting the repl
  --tokens    print the token stream
  --no-ast    don't print the syntax tree (only useful with -s)
  --dump-grammar <file>  write the compiled rule trees to a file
  -h  --help  this message
```

## On grammar and semantics

Reusing a built-in syntax name (`STX_IF`, `STX_WHILE`, ...) for a rule that
matches its intent means a future interpreter built the same way the
original flexible-parser's was - switching on the tag, pulling children by
role rather than fixed position - would run it without modification, even
across grammars with completely different concrete syntax (see
`resources/grammar.txt` vs. `resources/grammar-mini.txt`). Minting a new
rule name, or reusing an existing one for something structurally
different, parses and prints in the AST fine but carries no built-in
meaning - there's no enforcement of that convention at the grammar layer,
by design; giving new syntax real semantics is deliberately left as a
separate, later step.

## License

MIT, plus a credit to Robert Nystrom for `scanner.c`'s heritage
(Crafting Interpreters) - see [LICENSE](LICENSE) for full provenance, and
[THIRD_PARTY_LICENSES](THIRD_PARTY_LICENSES) for vendored `linenoise`.
