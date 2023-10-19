//
// Created by pha on 10/18/23.
//

#include "lexer.h"

bool is_number(const char cur) {
    return cur >= '0' && cur <= '9';
}

void Lexer::consume() {
    this->skip_whitespace();

    if (this->m_position == this->m_source.length()) {
        this->m_token = Token(Type::END, {.none = nullptr });
        return;
    }

    if (is_number(this->peek(0))) {
        this->consume_number();
        return;
    }

    switch (this->peek(0)) {
        case '+':
            this->m_token = Token(Type::PLUS, {.none = nullptr });
            break;
        case '-':
            this->m_token = Token(Type::MINUS, {.none = nullptr });
            break;
        case '*':
            this->m_token = Token(Type::STAR, {.none = nullptr });
            break;
        case '/':
            this->m_token = Token(Type::SLASH, {.none = nullptr });
            break;
        default:
            this->m_token = Token(Type::INVALID, {.none = nullptr });
            break;
    }

    this->m_position++;
}

void Lexer::consume_number() {
    int64_t base = 1;
    int64_t value = 0;

    while (is_number(this->peek(0))) {
        value *= base;
        value  += this->peek(0) - '0';
        base *= 10;

        this->m_position++;
    }

    this->m_token = Token(Type::NUMBER, {.number = value});
}

void Lexer::skip_whitespace() {
    while (this->m_position < this->m_source.length() && this->m_source[this->m_position] == ' ') {
        this->m_position++;
    }
}

char Lexer::peek(size_t offset) {
    return this->m_source[m_position - offset];
}

Token &Lexer::next_token() {
    this->consume();
    return this->m_token;
}
