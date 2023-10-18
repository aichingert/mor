//
// Created by pha on 10/18/23.
//

#include "token.h"

Type Token::get_type() {
    return this->m_type;
}

Value Token::get_value() {
    return this->m_value;
}