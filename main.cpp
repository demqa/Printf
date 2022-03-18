
extern "C" int RTprintf(const char *string, ...);

int main()
{
    int x = RTprintf("I love %x na %b%%%c\nI %s %x na %d%%%c%b\n", 3802, 8, '!', "love", 3802, 100, 33, 255);

    RTprintf("number that RTprintf returned is %d\n", x);

    return 0;
}
