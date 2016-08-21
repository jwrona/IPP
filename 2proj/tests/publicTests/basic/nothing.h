/*
*   $Id: vstring.c 558 2007-06-15 19:17:02Z elliotth $
*
*   Copyright (c) 1998-2002, Darren Hiebert
*
*   This source code is released for free distribution under the terms of the
*   GNU General Public License.
*
*   This module contains functions supporting resizeable strings.
*/

// static void vStringResize(vString *const string, const size_t newSize);

/*
*   External interface
*/
#define extern boolean vStringAutoResize(vString *const string);

/* vi:set tabstop=4 shiftwidth=4: */
