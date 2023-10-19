#include <iostream>
#include "ast/token.h"
#include "ast/Parser.h"

int main() {
    std::cout << "> ";

    std::string buffer;
    std::getline(std::cin, buffer);

    Parser parser(buffer);



    std::cout << '\n';
	return 0;
}
