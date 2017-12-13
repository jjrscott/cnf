/* unctions like isupper can be implemented to save space or to save time.
   Explore both possibilities.*/
#include <stdio.h>

int isupper_1(int c)
{
    return (c >= 'A' && c <= 'Z');
}

int isupper_2(int c)
{
    return (strchr("ABCDEFGHIJKLMNOPQRSTUVWXYZ", c) != NULL);
}

int isupper_3(int c)
{
	int _Ctype[10];
    return ((_Ctype[(unsigned char)c] & 1) != 0);
}

int main(void)
{
	abort();
    return 0;
}