/*
*       asc2c3.c
*
*       Copyright(c)2012 FIS
*       All Rights Reserved
*
*       Author: Manoj Thoniyil
*       Date: 14 Feb 2012
*
*       DESC:   External Call from MUMPS to translate from
                ASCII to COMP3 packed.
*
* $Id: $
*
* $Log: asc2c3.c,v $
*  Revision 1.2  12/09/04  Krisham()
*  Modified asc2c3 to return -1, when error occurs.
*  Verify if the input value contains anything other than numbers. 
*  Return an error, if it does. 
*
*  Revision 1.1  12/02/14  thoniyim ()
*  Initial revision
*
* $Revision: 1.2 $
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "extcall.h"
#include "scatype.h"

void asc2c3(int count, STR_DESCRIPTOR *inText, STR_DESCRIPTOR *Packed, 
	    int BufSize, int *rc)
{
        char Sign = '0' + 0x0C;
        size_t Digits;
        int i=0,bufLen=BufSize*2;
        int j=0;
        unsigned char *PkdPtr = Packed->str;
	unsigned char *Text = inText->str;
        unsigned char tempStr[bufLen];
 
        /* Count the number of digits to see if we need to pad or if the
        destination is too small. */
        Digits = inText->length;
 
#ifdef DEBUG
	fprintf(stderr,"\nInput text -> \n",Text[i]);
	for (i= 0; i < Digits; i++)
		fprintf(stderr,"%x ",Text[i]);
	fprintf(stderr,"\n");
	fflush(stderr);
#endif
        /* Validate parameters */
        if (! PkdPtr || ! Text)
	{
		*rc = -1;
                return;
 	}
        /* Check for a sign character */
        switch (*Text)
        {
        case '+':
                Sign = '0' + 0x0C;
                Text++; /* skip past sign character */
		Digits--;
                break;
        case '-':
                Sign = '0' + 0x0D;
                Text++; /* skip past sign character */
		Digits--;
                break;
        }
 
        if (Digits > bufLen)
		{
				*rc = -1;
                return;
		}
        else
        {
                tempStr[bufLen-1] = Sign;
                for (i = bufLen-2,j=Digits-1; i >= 0; i--,j--)
                {
                        if (j < 0)
                        {
                                tempStr[i] = '0';
                                continue;
                        }
                        if (Text[j] != '.')
			{
				if ((Text[j] < 58) && (Text[j] > 47))
                                	tempStr[i] = Text[j];
				else
				{
					*rc = -1;
					return;
				}
			}
                        else
                                i++;
#ifdef DEBUG
	fprintf(stderr,"tempStr -> %x\tText -> %x\n",tempStr[i],Text[j]);
	fflush(stderr);
#endif
                }
        }
 
#ifdef DEBUG
	fprintf(stderr,"\ntempStr -> %s\n",tempStr);
	fflush(stderr);
#endif
        /* Convert the remaining digits two at a time, except for the last. */
        for (i = 0;i < bufLen;i+=2)
        {
                *PkdPtr = (tempStr[i] - '0') << 4 | (tempStr[i+1] - '0');
                PkdPtr += 1;
        }

#ifdef DEBUG
	fprintf(stderr,"\nPacked -> \n");
        for (i = 0; i < BufSize; i++)
                fprintf(stderr, "%2x ",Packed->str[i]);

	fflush(stderr);
#endif

	Packed->length = BufSize;
	*rc = MUMPS_SUCCESS; 
        return;
}
