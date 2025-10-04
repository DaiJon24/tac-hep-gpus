#include <iostream>
#include <vector>
#include <string>

void rockpaperscissors() {
    std::cout << "Player 1 `s turn (rock, paper, scissors): ";
    std::string player1;
    std::cin >> player1;
    if (player1 != "rock" && player1 != "paper" && player1 != "scissors") {
        std::cout << "Invalid input. Please enter rock, paper, or scissors." << std::endl;
        return;
    }
    
    std::cout << "Player 2 `s turn (rock, paper, scissors): ";
    std::string player2;
    std::cin >> player2; 
    
    if (player2 != "rock" && player2 != "paper" && player2 != "scissors") {
        std:: cout << "Invalid input. Please enter rock, paper, or scissors." << std::endl;
        return;
    } 
      
    if (player1 == player2) {
        std::cout << "It's a tie!" << std::endl;
    } else if ((player1 == "rock" && player2 == "scissors") ||
               (player1 == "scissors" && player2 == "paper") ||
               (player1 == "paper" && player2 == "rock")) {
        std::cout << "Player 1 wins!" << std::endl;
    } else {
        std::cout << "Player 2 wins!" << std::endl;
    }
}


int main(){

    rockpaperscissors();
    return 0;
}