#ifndef INTERP_H
#define INTERP_H

/* interp.h - a tree-walking interpreter over the parsed AST.
 *
 * It switches on the built-in STX_* types, so it understands whatever subset
 * of the grammar uses those names. A grammar that renames or invents rules
 * still parses and dumps fine; it just has no semantics attached here - see
 * README.md's "On grammar and semantics" section, and src/shape.h for
 * checking a grammar's rules actually have the parts a tag needs before
 * ever reaching this.
 *
 * This exists as the reference implementation for a VM built later (see
 * README.md's roadmap): simpler to get right than a bytecode compiler, and
 * once the VM exists, running the same programs through both and diffing
 * the output is what actually validates the VM.
 *
 * An Interp holds all program state, so the REPL can create one and reuse it
 * across entries while a batch run creates one and throws it away.
 */

#include "common.h"
#include "arena.h"
#include "registry.h"
#include "ast_node.h"

typedef struct s_Interp Interp;

/* Allocated from `arena`; freed when the arena is torn down. */
Interp *interpCreate(Registry *reg, Arena *arena);

typedef enum {
	EXEC_OK = 0,
	EXEC_ERROR,  /* a runtime error was reported */
	EXEC_EXITED, /* the program called exit(...) */
} ExecResult;

/* Runs a tree. `out_exit` receives the program's exit value, which is set
 * from exit(...) or a top-level return. */
ExecResult interpExec(Interp *in, const SyntaxNode *root, int *out_exit);

/* REPL form: runs a tree and, when it is an expression rather than a
 * statement, prints the resulting value. */
ExecResult interpExecEcho(Interp *in, const SyntaxNode *root, int *out_exit);

/* True for node types the interpreter evaluates to a value. The REPL uses
 * this to decide between running a statement and echoing an expression. */
bool interpIsExpression(const SyntaxNode *node);

/* True for a tag execNode/evalNode can do something meaningful with as an
 * independent, standalone unit - a real statement type, an expression type
 * (see interpIsExpression), or a grammar-minted tag (>= STX__COUNT, treated
 * as transparent grouping). False for a tag that only exists to be
 * referenced from inside another rule's body (STX_EQUAL, STX_ARITHOP,
 * STX_VTYPE, ...) - parseable in isolation, perhaps, but never meaningful
 * as a whole entry on its own. The REPL uses this to decide which candidate
 * rules are worth trying as the next statement in an entry; keep it in sync
 * with execNode's own switch in interp.c. */
bool interpIsRunnable(SYNTAX_TYPE type);

/* Convenience wrapper for a one-shot run: creates an Interp, hoists function
 * definitions, executes. Returns 0 on success. */
int runProgram(const SyntaxNode *root, Registry *reg, Arena *arena, int *out_exit);

#endif // INTERP_H
