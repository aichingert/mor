cmake_minimum_required(VERSION 3.24)

project(lang)

add_executable(main src/main.cpp
        src/ast/lexer.h
        src/ast/token.h)

set(CMAKE_CXX_STANDARD 20)
