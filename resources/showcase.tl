// showcase.tl - exercises as much of the language as the interpreter
// currently supports in one coherent program: recursion, mutual recursion,
// iteration, string concatenation, operator precedence, shadowing,
// short-circuit boolean logic, compound assignment, and early exits via
// both `break` and `return`.
//
// Run with:
//   bin/repl2 -g resources/grammar.txt -s resources/showcase.tl

scope main {

	fn factorial(int n) => int {
		if (n <= 1) {
			return 1;
		}
		return n * factorial(n - 1);
	}

	// Euclid's algorithm - recursive, two parameters.
	fn gcd(int a, int b) => int {
		if (b == 0) {
			return a;
		}
		return gcd(b, a % b);
	}

	// Recursive and iterative fibonacci side by side, so the two can be
	// checked against each other.
	fn fibRec(int n) => int {
		if (n < 2) {
			return n;
		}
		return fibRec(n - 1) + fibRec(n - 2);
	}

	fn fibIter(int n) => int {
		int a = 0;
		int b = 1;
		int i = 0;
		while (i < n) {
			int next = a + b;
			a = b;
			b = next;
			i += 1;
		}
		return a;
	}

	// Mutual recursion: each function only knows about the other's name,
	// which only works because both are hoisted before either runs.
	fn isEven(int n) => bool {
		if (n == 0) {
			return true;
		}
		return isOdd(n - 1);
	}

	fn isOdd(int n) => bool {
		if (n == 0) {
			return false;
		}
		return isEven(n - 1);
	}

	// Trial division. `d * d <= n` instead of `d <= sqrt(n)` since there is
	// no sqrt() builtin - just integer arithmetic.
	fn isPrime(int n) => bool {
		if (n < 2) {
			return false;
		}
		int d = 2;
		while (d * d <= n) {
			if (n % d == 0) {
				return false;
			}
			d += 1;
		}
		return true;
	}

	// No closures - every value a function needs comes in as a parameter,
	// nothing is captured from an enclosing scope.
	fn describe(int n, bool prime) => Str {
		if (prime) {
			return "prime";
		}
		if (n % 2 == 0) {
			return "even composite";
		}
		return "odd composite";
	}

	print("=== factorial & gcd ===");
	print("5! =", factorial(5));
	print("10! =", factorial(10));
	print("gcd(48, 18) =", gcd(48, 18));
	print("gcd(17, 5) =", gcd(17, 5));

	print("=== fibonacci: recursive vs iterative ===");
	bool allMatch = true;
	for (int i = 0; i < 12; i++) {
		int r = fibRec(i);
		int it = fibIter(i);
		if (r != it) {
			allMatch = false;
		}
		print("fib(", i, ") recursive =", r, "iterative =", it);
	}
	print("recursive and iterative agreed on all 12 =", allMatch);

	print("=== even/odd via mutual recursion ===");
	for (int i = 0; i < 6; i++) {
		print(i, "isEven =", isEven(i), "isOdd =", isOdd(i));
	}

	print("=== primes up to 40, with early exit via break ===");
	int count = 0;
	int n = 2;
	while (true) {
		if (n > 40) {
			break;
		}
		if (isPrime(n)) {
			count += 1;
			print(n, "is", describe(n, true));
		}
		n += 1;
	}
	print("found", count, "primes below 40");

	print("=== operator precedence, unary, and shadowing ===");
	int x = 2 + 3 * 4 - 6 / 2;         // 2 + 12 - 3 = 11
	print("2 + 3 * 4 - 6 / 2 =", x);
	print("-x =", -x);
	print("!(x > 100) =", !(x > 100));

	int shadowed = 1;
	if (true) {
		int shadowed = shadowed + 100; // reads the outer 1, shadows it with 101
		print("inner shadowed =", shadowed);
	}
	print("outer shadowed =", shadowed);

	print("=== short-circuit boolean logic ===");
	// undefinedThing() is never called because `false and ...` short-circuits.
	if (false and undefinedThing()) {
		print("unreachable");
	} else {
		print("short-circuit held");
	}
	int denom = 0;
	if (denom != 0 and (100 / denom) > 1) {
		print("unreachable, no division by zero attempted");
	} else {
		print("guarded against division by zero");
	}

	print("=== string concatenation ===");
	Str greeting = "hello";
	Str name = "repl2";
	Str message = greeting + ", " + name + "!";
	print(message);

	print("=== compound assignment and increment/decrement ===");
	int acc = 10;
	acc += 5;
	acc -= 2;
	acc *= 3;
	print("10 += 5 -= 2 *= 3 =", acc);
	acc++;
	acc--;
	acc--;
	print("after ++ then -- twice =", acc);

	print("done");
}
