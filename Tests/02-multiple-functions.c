
int foo(void)
{
	return 10;
};

int main(void)
{
	return 10 + foo() * 4 + ~3;
};