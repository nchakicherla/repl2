#include <stdio.h>
#include <string.h>

#include "common.h"
#include "file.h"
#include "interp.h"
#include "parser.h"
#include "repl.h"
#include "shape.h"

static const char *DEFAULT_GRAMMAR = "./resources/grammar.txt";

static void usage(void) {
	printf("usage: repl2 [options]\n");
	printf("  -g <file>   grammar file      (default %s)\n", DEFAULT_GRAMMAR);
	printf("  -s <file>   parse and run this source file, instead of starting\n");
	printf("              the repl\n");
	printf("  --tokens    print the token stream (only useful with -s)\n");
	printf("  --ast       print the syntax tree (only useful with -s)\n");
	printf("  --check-shapes  check the parsed tree against the built-in tags'\n");
	printf("                  structural requirements (only useful with -s)\n");
	printf("  --parse-only  parse (and print --tokens/--ast/--check-shapes, if\n");
	printf("                given) but don't run it (only useful with -s)\n");
	printf("  --dump-grammar <file>  write the compiled rule trees to a file\n");
	printf("  -h  --help  this message\n");
}

int main(int argc, char **argv) {
	const char *grammar_file = DEFAULT_GRAMMAR;
	const char *source_file = NULL;
	const char *grammar_log = NULL;
	bool show_ast = false;
	bool show_tokens = false;
	bool check_shapes = false;
	bool parse_only = false;

	Parser parser;
	ParseStatus status;
	char *source;
	int exit_code = 0;

	for (int i = 1; i < argc; i++) {
		if (0 == strcmp(argv[i], "-g") && i + 1 < argc) {
			grammar_file = argv[++i];
		} else if (0 == strcmp(argv[i], "-s") && i + 1 < argc) {
			source_file = argv[++i];
		} else if (0 == strcmp(argv[i], "--dump-grammar") && i + 1 < argc) {
			grammar_log = argv[++i];
		} else if (0 == strcmp(argv[i], "--tokens")) {
			show_tokens = true;
		} else if (0 == strcmp(argv[i], "--ast")) {
			show_ast = true;
		} else if (0 == strcmp(argv[i], "--check-shapes")) {
			check_shapes = true;
		} else if (0 == strcmp(argv[i], "--parse-only")) {
			parse_only = true;
		} else if (0 == strcmp(argv[i], "-h") || 0 == strcmp(argv[i], "--help")) {
			usage();
			return 0;
		} else {
			fprintf(stderr, "unrecognized argument: %s\n", argv[i]);
			usage();
			return 1;
		}
	}

	initParser(&parser);

	/* The grammar defines the token alphabet, so it is loaded before anything
	 * is read - including in the repl, which has no source file at all. */
	status = parserSetGrammar(&parser, grammar_file);
	if (status != PARSE_OK) {
		fprintf(stderr, "%s\n", parseStatusMessage(status));
		exit_code = 1;
		goto done;
	}

	if (grammar_log) {
		FILE *log = fopen(grammar_log, "w");
		if (log) {
			fPrintGrammar(&parser.grammar, log);
			fclose(log);
		}
	}

	/* No source file: the repl is the point of this program, so it is the
	 * default rather than something an extra flag has to ask for. */
	if (!source_file) {
		exit_code = runRepl(&parser, grammar_file);
		goto done;
	}

	source = tryReadFile(source_file, &parser.arena);
	if (!source) {
		fprintf(stderr, "could not read source file '%s'\n", source_file);
		exit_code = 1;
		goto done;
	}

	status = parserParseSource(&parser, source);
	if (status != PARSE_OK) {
		fprintf(stderr, "%s\n", parseStatusMessage(status));
		exit_code = 1;
		goto done;
	}

	if (show_tokens) {
		for (size_t i = 0; i < parser.n_tokens; i++) {
			printToken(&parser.reg, &parser.tokens[i]);
		}
	}

	if (show_ast) {
		printSyntaxNode(&parser.reg, parser.ast, 0);
	}

	if (check_shapes) {
		size_t violations = checkShapes(&parser.reg, parser.ast, stdout);
		if (violations == 0) {
			printf("no shape issues found\n");
		}
	}

	if (!parse_only) {
		int program_exit = 0;
		if (0 != runProgram(parser.ast, &parser.reg, &parser.arena, &program_exit)) {
			exit_code = 1;
			goto done;
		}
		exit_code = program_exit;
	}

done:
	termParser(&parser);
	return exit_code;
}
