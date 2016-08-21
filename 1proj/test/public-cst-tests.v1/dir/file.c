#include <stdio.h>
#include <stdlib.h>
#include "subdir/file.h"

#define STRUCT_PTR struct {int i;} *

// This function does nothing useful.
int func(int i, ...) {
	return i + i;
}

/*
    + + + + + + Main. + + + + + + + + +
*/
int main(void) {
	int i = 1;
	char s[10] = "- - - -";

	i++;
	s[1] = 'b';
	i += func(4);

	STRUCT_PTR t = malloc(sizeof(*t));
	if (!t) {
		return EXIT_FAILURE;
	}
	t->i = 1 == 2 ? 3 : -5;

	return EXIT_SUCCESS;
}

// zZ
