/*
*	mathutils.c
*
*	Copyright(c) 2010 FIS
*	All Rights Reserved
*
*	Author: Manoj Thoniyil
*	Date: 21 September 2010
*
*	DESC: This program contains a collection of math utilities.
*
*   $Id$
*   $Log: mathutils.c,v $
*
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "extcall.h"

/*
*	expsca()
*	
*	This function calls the "C" function exp(), which returns the
*	Exponential function value for the Value Passed in by a
*	Mumps program.
*/
void expsca(int count,
	STR_DESCRIPTOR *in_data,
	SLONG length,
	STR_DESCRIPTOR *out_data)
{
	double  i,j;
 
	in_data->str[length]='\0';
	i = atof(in_data->str);
	j = exp(i);
	(void)sprintf(out_data->str,"%.14f",j);
	out_data->length = strlen(out_data->str);
}

/*
*	lnx()
*
*	This routine calls the "C" routine lnx, which returns the
*	Natural Logrithmic value of the Value Passed in by the
*	Mumps program.
*/
void lnx(int count,
	STR_DESCRIPTOR *in_data,
	SLONG length,
	STR_DESCRIPTOR *out_data)
{
	double  i,j;
 
	in_data->str[length]='\0';
	i = atof(in_data->str);
	j = log(i);
	(void)sprintf(out_data->str,"%.15f",j);
	out_data->length = strlen(out_data->str);
}

/*
*	logsca()
*
*	This routine calls the "C" routine log10, which returns the
*	Base 10 Logarithmic value of the Value Passed in by a
*	Mumps program.
*/
void logsca(int count,
	STR_DESCRIPTOR *in_data,
	SLONG length,
	STR_DESCRIPTOR *out_data)
{
	double  i,j;
 
	in_data->str[length]='\0';
	i = atof(in_data->str);
	j = log10(i);
	(void)sprintf(out_data->str,"%.15f",j);
	out_data->length = strlen(out_data->str);
}

