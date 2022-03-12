### Printf

### There are supported printf modifiers:
*%c* ,*%s*, *%d*, *%x*, *%o*, *%b*, *%%*


#### Compiling:
*x86-64*
```
nasm -f elf64 printf.asm
ld -s -o printf printf.o
```

#### Start:
```
./printf
```


