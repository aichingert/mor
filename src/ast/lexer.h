//
// Created by pha on 18/10/23.
//

#ifndef LANG_LEXER_H
#define LANG_LEXER_H

#include <utility>
#include <vector>
#include <string>
#include "token.h"

bool is_number();

class Lexer {
public:
    explicit Lexer(std::string_view source)
        : m_source(source)
        , m_token(Token(Type::END,  {.none = nullptr}))
        , m_position(0)
    {
    }

    ~Lexer() = default;

    Token &next_token();

private:
    char peek(size_t offset);
    void consume();
    void consume_number();
    void skip_whitespace();

    Token m_token;
    std::string_view m_source;
    size_t m_position;
};

#endif //LANG_LEXER_H
