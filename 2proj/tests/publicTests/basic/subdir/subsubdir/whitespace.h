/*
*   $Id: debug.h 558 2007-06-15 19:17:02Z elliotth $
*
*   Copyright (c) 1998-2002, Darren Hiebert
*
*   This source code is released for free distribution under the terms of the
*   GNU General Public License.
*
*   External interface to debug.c
*/

/*
*   Function prototypes
*/
extern inline void
lineBreak              (     void     )

;


extern      inline void           debugPrintf
(
const enum eDebugLevels level,
const char   		*  const                    format,
...)
{
return NULL;
}

extern void
debugPutc
(
const int level
,
const int c)
;

/* vi:set tabstop=4 shiftwidth=4: */
