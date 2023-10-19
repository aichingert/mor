//
// Created by pha on 19/10/23.
//

#include "Parser.h"

Parser::Parser(std::string_view source) {
    Lexer lexer(source);
    Token token = lexer.next_token();

    while (token.get_type() != Type::END) {
        m_tokens.push_back(token);
        token = lexer.next_token();
    }
}
