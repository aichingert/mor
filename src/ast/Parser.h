//
// Created by pha on 19/10/23.
//

#ifndef LANG_PARSER_H
#define LANG_PARSER_H

#include <cstdint>
#include <string>
#include <vector>
#include <variant>
#include "token.h"
#include "lexer.h"



class Parser {
public:
    Parser() = default;
    explicit Parser(std::string_view source);

    Expr parse_binary_expr();

    ~Parser() = default;

private:
    std::vector<Token> m_tokens;
    size_t m_position = 0;

};


#endif //LANG_PARSER_H
