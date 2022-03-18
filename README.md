### Printf

### There are supported printf modifiers:
*%c* ,*%s*, *%d*, *%x*, *%o*, *%b*, *%%*

#### How to call in C:

**RTprintf(fmt_string, arg1, arg2, arg3, ...);**

Number of arguments have to be equal to number of % specificators, which are not %%

fmt_string can include all the % specificators desribed in the top.

Number of printed arguments returned as function result, you can use it to check it. If that number isn't equal to number of arguments you putted, program behaviour is undefined. 

#### Before Compiling:
You have to change format string in main.c, to print something you want))))

#### Compiling:
*x86-64*
```
nasm -felf64 -o printf.o printf.asm
gcc -c main.cpp
ld -o printf printf.o main.o
```

#### Start:
```
./printf
```

