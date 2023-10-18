//
// Created by pha on 18/10/23.
//

#ifndef LANG_LEXER_H
#define LANG_LEXER_H

#include <utility>
#include <vector>
#include <string>
#include "token.h"

class Lexer {
public:
    explicit Lexer(std::string source)
        : m_source(std::move(source))
        , m_current_token(new Token(Type::END,  {.eof = nullptr}))
        , m_position(0)
        , m_tokens({})
    {
    }

    ~Lexer() = default;

    virtual Token* next_token();

private:
    virtual char peek(size_t offset);
    virtual void consume();

    std::vector<Token> m_tokens;
    Token* m_current_token;
    std::string m_source;
    size_t m_position;
};

#endif //LANG_LEXER_H
