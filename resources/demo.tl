// Exercises the parts of the language the tree-walking interpreter implements.

scope main {

	fn fib (int n) => int {
		if (n < 2) {
			return n;
		}
		return fib(n - 1) + fib(n - 2);
	}

	fn scale (flt x, flt k) => flt {
		return x * k;
	}

	// precedence is applied by the interpreter, not the grammar
	int a = 1 + 2 * 3;
	print("1 + 2 * 3 =", a);
	print("(1 + 2) * 3 =", (1 + 2) * 3);
	print("7 / 2 =", 7 / 2);
	print("7 % 3 =", 7 % 3);
	print("7.0 / 2 =", 7.0 / 2);

	// unary
	print("-a =", -a);
	print("!true =", !true);

	// strings
	Str greeting = "hello";
	print(greeting + ", world");

	// comparison and booleans
	print("a > 5 =", a > 5);
	print("a == 7 =", a == 7);

	// short-circuit: undefinedFn is never called
	if (false and undefinedFn()) {
		print("unreachable");
	} else {
		print("short-circuit held");
	}

	// if / else if / else
	int grade = 85;
	if (grade > 89) {
		print("A");
	} else if (grade > 79) {
		print("B");
	} else {
		print("C");
	}

	// while with break
	int i = 0;
	while (true) {
		if (i > 2) {
			break;
		}
		print("while", i);
		i += 1;
	}

	// for with a scoped loop variable
	for (int k = 0; k < 3; k++) {
		print("for", k);
	}

	// recursion
	for (int f = 0; f < 8; f++) {
		print("fib", f, "=", fib(f));
	}

	// float arithmetic through a call
	print("scale(2.5, 4) =", scale(2.5, 4));

	return 0;
}
