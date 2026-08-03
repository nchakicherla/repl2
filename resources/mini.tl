// Written against grammar-mini.txt: `let`, `:=`, and no parens on conditions.
{
	let total := 0;
	let n := 5;

	loop n > 0 {
		total += n;
		print("adding", n, "-> total", total);
		n -= 1;
	}

	if total == 15 {
		print("sum 1..5 =", total);
	} else {
		print("unexpected", total);
	}

	print("2 + 3 * 4 =", 2 + 3 * 4);
}
