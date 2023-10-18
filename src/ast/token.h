//
// Created by pha on 18/10/23.
//

#ifndef LANG_TOKEN_H
#define LANG_TOKEN_H

#include <cstdint>

enum class Type {
    NUMBER,
    PLUS,
    MINUS,
    STAR,
    SLASH,
    INVALID,
    END, // since EOF is not usable
};

union Value {
    int64_t number;
    void* eof;
};

class Token {
public:
    Token(Type type, Value value)
        : m_type(type)
        , m_value(value)
    {
    }

    virtual Type get_type();
    virtual Value get_value();

    ~Token() = default;

private:
    Type m_type;
    Value m_value;
};

#endif //LANG_TOKEN_H
