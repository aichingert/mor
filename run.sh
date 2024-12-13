#!/bin/sh

nasm -f elf64 main.asm
ld -o main main.o
./main

echo ""
echo "SYS_EXIT: $?"
objdump -Mintel -d main

rm main
rm main.o
