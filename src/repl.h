#ifndef REPL_H
#define REPL_H

/* repl.h - interactive read/parse/print loop.
 *
 * Each entry is scanned and matched against the loaded grammar; the resulting
 * syntax tree (and, if enabled, the token stream) is printed. Nothing is
 * executed - this REPL exists to exercise a grammar, not a language.
 */

#include "parser.h"

/* Takes over stdin until the user exits. Returns the process exit code. */
int runRepl(Parser *parser, const char *grammar_file);

#endif // REPL_H
