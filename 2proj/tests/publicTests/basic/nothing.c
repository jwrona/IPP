/*
*   $Id: strlist.c 443 2006-05-30 04:37:13Z darren $
*
*   Copyright (c) 1999-2002, Darren Hiebert
*
*   This source code is released for free distribution under the terms of the
*   GNU General Public License.
*
*   This module contains functions managing resizable string lists.
*/

/*
*   INCLUDE FILES
*/
#include "general.h"  /* must always come first */

#include <string.h>

#include "debug.h"
#include "read.h"
#include "routines.h"
#include "strlist.h"

/*
*   FUNCTION DEFINITIONS
*/

extern stringList *do_not_analyze(void);

/* vi:set tabstop=4 shiftwidth=4: */
