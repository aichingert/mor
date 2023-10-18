//
// Created by pha on 18/10/23.
//

#ifndef LANG_TOKEN_H
#define LANG_TOKEN_H

template<typename T>
class Token {
public:
    int getType();
    
private:
    T type;
};

#endif //LANG_TOKEN_H
