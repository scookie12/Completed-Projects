// DO NOT MODIFY THIS FILE!!
//
// Output should be the following EXACTLY!!
//
// Your piggy bank has $0.50
// My piggy bank has $27.25
// Cannot deposit negative
// Your piggy bank has $0.50
// My piggy bank has $27.26
// Cannot withdraw negative
// Cannot withdraw more money than is available
// Your piggy bank has $0.50
// My piggy bank has $27.27
// NOOO!!! You lost $0.50
// Cannot withdraw money into broken bank
// Cannot deposit money into broken bank
// Piggy bank had $27.27 upon deconstruction.
#include <iomanip>
#include <iostream>
#include "PiggyBank.hpp"
void printSavings(PiggyBank const& yourBank, PiggyBank const& myBank)
{
    std::cout << "Your piggy bank has $" << std::fixed << std::setprecision(2)
        << yourBank.countSavings() << std::endl;
    std::cout << "My piggy bank has $" << std::fixed << std::setprecision(2)
        << myBank.countSavings() << std::endl;
}
void printSavingsCopy(PiggyBank yourBank, PiggyBank myBank)
{
    std::cout << "Your piggy bank has $" << yourBank.countSavings() << std::endl;
    std::cout << "My piggy bank has $" << myBank.countSavings() << std::endl;
}
int main()
{
    // Construct the piggy banks
    PiggyBank yourBank;
    PiggyBank myBank(26.5);
    // Make deposits
    yourBank.deposit(.5);
    myBank.deposit(.75);
    printSavings(yourBank, myBank);
    // This function call should not compile!
    // printSavingsCopy(yourBank, myBank);
    yourBank.deposit(-4.5);
    myBank.deposit(.01);
    printSavings(yourBank, myBank);
    yourBank.withdraw(-.02);
    myBank.deposit(.01);
    yourBank.withdraw(1000);
    printSavings(yourBank, myBank);
    yourBank.smash();
    yourBank.withdraw(.02);
    yourBank.deposit(.01);
}