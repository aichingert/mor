#!/bin/sh

nasm -f elf64 main.asm
ld -o main main.o
./main

echo $?

rm main
rm main.o
