#ifndef PIGGY_BANK_HPP
#define PIGGY_BANK_HPP


class PiggyBank
{
public:
	// Default Constructor
	PiggyBank();

	// Parameter Constructor
	PiggyBank(double money);

	// Deconstructor
	~PiggyBank();

	// Deleted Copy Constructor, might need one for myBank
	PiggyBank(PiggyBank const& yourBank) = delete;

	// countSavings() function
	double countSavings() const;

	// deposit function
	void deposit(double money);

	// withdraw function
	void withdraw(double money);

	// smash function
	void smash();

private:
	//functions within PiggyBank.hpp can access these
	double m_balance;
	bool m_smashed;
};


#endif