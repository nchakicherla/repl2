scope main {
	flt a = 1 + (2 * (3 + 5)) / 4; 
	print(a);

	flt b = a + 3;
	print(b);

	flt c = 7.9 + (3 * 4.2) + (4 / 9);

	for (int i = 3; i > 0; i--) {
		print(i);
	}

	while (a > 3) {
		print(a);
		a = a - 1;
	}

	test.test2 = a + 3;
	test.test3 = "teststr";

	if (a > 3) {
		print(a);
	} else if (a < 3) {
		print(b);
	} else {
		int h = print(0);
	}

	fn testFn (int a, str b) {
		return (a * b);
	}

	3 or 4;
	return 0;
}

/*
*/

// int a = (3.14 * 2);

// a.a = 3;

//int a.test.test2 = 3;