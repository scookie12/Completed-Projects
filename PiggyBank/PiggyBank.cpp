#include <iostream>
#include <iomanip>
#include "PiggyBank.hpp"

PiggyBank::PiggyBank() // done
{
	m_balance = 0;
	m_smashed = false;
}

PiggyBank::PiggyBank(double money)  // done
{
	m_balance = money;
	m_smashed = false;
}

double PiggyBank::countSavings() const // done
{
	return m_balance;
}

PiggyBank::~PiggyBank() // done
{
	if (m_smashed == false)
	{
		std::cout << "Piggy bank had $" << std::fixed << std::setprecision(2) << m_balance << " upon deconstruction" << std::endl;
	}
}

void PiggyBank::deposit(double money)
{
	if (m_smashed == true)
	{
		std::cout << "Cannot deposit money into broken bank" << std::endl;
	}
	else if (money < 0)
	{
		std::cout << "Cannot deposit negative" << std::endl;
	}
	else
	{
		m_balance = m_balance + money;
	}
}

void PiggyBank::withdraw(double money)
{
	if (money < 0)
	{
		std::cout << "Cannot withdraw negative" << std::endl;
	}
	else if (m_smashed)
	{
		std::cout << "Cannot withdraw money into broken bank" << std::endl;
	}
	else if (money > m_balance)
	{
		std::cout << "Cannot withdraw more money than is available" << std::endl;
	}
	else
	{
		m_balance = m_balance - money;
	}
}

void PiggyBank::smash() // oh no...our piggy bank...it's broken
{
	m_smashed = true;
	if (m_balance > 0)
	{
		std::cout << "NOOO!! You lost $" << std::fixed << std::setprecision(2) << m_balance << std::endl;
	}
	m_balance = 0;
}