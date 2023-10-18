#include <iostream>
#include "ast/lexer.h"

int main() {
    auto lexer = new Lexer("10 + 13");

    auto current_token = lexer->next_token();

	std::cout << "Lol" << "\n";
	return 0;
}
