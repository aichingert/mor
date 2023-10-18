//
// Created by pha on 10/18/23.
//

#include "lexer.h"

void Lexer::consume() {}


char Lexer::peek(size_t offset) {return this->m_source[m_position - offset];}

Token* Lexer::next_token() {return this->m_current_token;}
