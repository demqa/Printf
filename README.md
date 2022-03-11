### Printf

### There are supported printf modifiers:
*%c* ,*%s*, *%d*, *%x*, *%o*, *%b*, *%%*

#### How to call:

**printf(fmt_string, arg1, arg2, arg3, ...);**

Number of arguments have to be equal to number of % specificators, which are not %%
fmt_string can include all the % specificators desribed in the top

#### Before Compiling:
You have to change format string in main.c, to print something you want))))

#### Compiling:
*x86-64*
```
nasm -f elf64 -w+all -l printf.lst printf.asm
gcc -c main.c
gcc -no-pie -o printf main.o printf.o -lc
```

#### Start:
```
./printf
```

