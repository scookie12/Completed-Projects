
#include <gtest/gtest.h>

#include "BST.hpp"

TEST(OwnWrittenTests, Add)
{
	Bst<std::string, size_t> bst;
	bst.add("10", 4);
	bst.add("8", 9);
	bst.add("9", 5);
	bst.add("14", 22);
	bst.add("7", 0);


	EXPECT_EQ(bst.at("10"), 4);
	EXPECT_EQ(bst.at("8"), 9);
	EXPECT_EQ(bst.at("9"), 5);
	EXPECT_EQ(bst.at("7"), 0);
	EXPECT_EQ(bst.at("14"), 22);

	EXPECT_EQ(bst.size(), 5);
}

TEST(OwnWrittenTests, AddNegative)
{
	Bst<int, size_t> bst;
	bst.add(10, 4);
	bst.add(-8, 9);
	bst.add(9, 5);
	bst.add(-14, 22);
	bst.add(7, 2);
	bst.add(12, 5);

	std::vector<Direction> nfourteen = { Direction::LEFT, Direction::LEFT };
	std::vector<Direction> seven = { Direction::LEFT, Direction::RIGHT, Direction::LEFT };
	std::vector<Direction> nine = { Direction::LEFT, Direction::RIGHT };
	std::vector<Direction> neight = { Direction::LEFT };
	std::vector<Direction> twelve = { Direction::RIGHT };

	EXPECT_EQ(bst.traverse(neight), 9);
	EXPECT_EQ(bst.traverse(nfourteen), 22);
	EXPECT_EQ(bst.traverse(nine), 5);
	EXPECT_EQ(bst.traverse(seven), 2);
	EXPECT_EQ(bst.traverse(twelve), 5);
	EXPECT_EQ(bst.size(), 6);
}

TEST(OwnWrittenTests, At)
{
	Bst<std::string, size_t> bst;
	bst.add("10", 4);
	bst.add("8", 9);
	bst.add("9", 5);
	bst.add("14", 22);
	bst.add("7", 0);

	EXPECT_EQ(bst.at("10"), 4);
	EXPECT_EQ(bst.at("8"), 9);
	EXPECT_EQ(bst.at("9"), 5);
	EXPECT_EQ(bst.at("14"), 22);
	EXPECT_EQ(bst.at("7"), 0);
	EXPECT_ANY_THROW(bst.at("2"));
	EXPECT_EQ(bst.size(), 5);
}

TEST(OwnWrittenTests, opertest)
{
	Bst<std::string, size_t> bst;
	bst.add("10", 4);
	bst.add("8", 9);
	bst.add("-9", 5);
	bst.add("14", 22);
	bst.add("7", 0);

	EXPECT_EQ(bst["10"], 4);
	EXPECT_EQ(bst["14"], 22);
	EXPECT_EQ(bst["-9"], 5);
	EXPECT_EQ(bst.size(), 5);
}

TEST(OwnWrittenTests, update)
{
	Bst<std::string, size_t> bst;
	bst.add("10", 4);
	bst.add("8", 9);
	bst.add("9", 5);
	bst.add("14", 22);
	bst.add("7", 0);
	
	bst.update("7", 4);
	bst.update("14", 4);

	EXPECT_EQ(bst.at("10"), 4);
	EXPECT_EQ(bst.at("8"), 9);
	EXPECT_EQ(bst.at("9"), 5);
	EXPECT_EQ(bst.at("14"), 4);
	EXPECT_EQ(bst.at("7"), 4);
	EXPECT_ANY_THROW(bst.at("2"));
	EXPECT_EQ(bst.size(), 5);
}

TEST(OwnWrittenTests, remove)
{
	Bst<std::string, size_t> bst;
	bst.add("10", 4);
	bst.add("8", 9);
	bst.add("9", 5);
	bst.add("14", 22);
	bst.add("7", 0);
	bst.add("17", 17);

	bst.remove("7");
	bst.remove("14");
	bst.remove("17");


	EXPECT_EQ(bst.at("10"), 4);
	EXPECT_EQ(bst.at("8"), 9);
	EXPECT_EQ(bst.at("9"), 5);
	EXPECT_ANY_THROW(bst.at("7"));
	EXPECT_ANY_THROW(bst.at("14"));
	EXPECT_EQ(bst.size(), 3);
}



TEST(OwnWrittenTests, CopyTest)
{
	Bst<int, size_t> bst;
	bst.add(10, 4);
	bst.add(-8, 9);
	bst.add(9, 5);
	bst.add(-14, 22);
	bst.add(7, 0);
	bst.add(12, 5);

	Bst<int, size_t> copy(bst);

	std::vector<Direction> nfourteen = { Direction::LEFT, Direction::LEFT };
	std::vector<Direction> seven = { Direction::LEFT, Direction::RIGHT, Direction::LEFT };
	std::vector<Direction> nine = { Direction::LEFT, Direction::RIGHT };
	std::vector<Direction> neight = { Direction::LEFT };
	std::vector<Direction> twelve = { Direction::RIGHT };

	EXPECT_EQ(copy.traverse(neight), 9);
	EXPECT_EQ(copy.traverse(nfourteen), 22);
	EXPECT_EQ(copy.traverse(nine), 5);
	EXPECT_EQ(copy.traverse(seven), 0);
	EXPECT_EQ(copy.traverse(twelve), 5);
	EXPECT_EQ(copy.size(), 6);
}

TEST(OwnWrittenTests, BigTree)
{
	Bst<std::string, size_t> bst;
	bst.add("116", 4);
	bst.add("18", 9);
	bst.add("925", 5);
	bst.add("143", 22);
	bst.add("72", 0);

	bst.add("102", 4);
	bst.add("81", 9);
	bst.add("93", 5);
	bst.add("4", 22);
	bst.add("70", 0);

	bst.add("10", 4);
	bst.add("84", 9);
	bst.add("91", 5);
	bst.add("1", 22);
	bst.add("7", 0);

	bst.add("1000", 4);
	bst.add("85", 9);
	bst.add("99", 5);
	bst.add("124", 22);
	bst.add("71", 0);

	EXPECT_EQ(bst.size(), 20);
/*
	std::vector<Direction> onezerotwo = { Direction::LEFT, Direction::RIGHT, Direction::RIGHT };
	EXPECT_EQ(bst.traverse(onezerotwo), 4);

	std::vector<Direction> ninenine = { Direction::LEFT, Direction::RIGHT, Direction::RIGHT, Direction::LEFT, Direction::RIGHT, Direction::RIGHT };
	EXPECT_EQ(bst.traverse(ninenine), 5);

	std::vector<Direction> eightfive = { Direction::LEFT, Direction::RIGHT, Direction::RIGHT, Direction::LEFT, Direction::RIGHT, Direction::LEFT, Direction::RIGHT, Direction::LEFT };
	EXPECT_EQ(bst.traverse(eightfive), 9);

	bst.remove("70");
	EXPECT_EQ(bst.size(), 19);
	std::vector<Direction> sevenone = { Direction::LEFT, Direction::RIGHT, Direction::LEFT };
	EXPECT_EQ(bst.traverse(sevenone), 0);

	bst.remove("18");
	EXPECT_EQ(bst.size(), 18);
	std::vector<Direction> ten = { Direction::LEFT };
	EXPECT_EQ(bst.traverse(ten), 4);

	bst.remove("99");
	EXPECT_EQ(bst.size(), 17);
	
	bst.update("925", 51);
	std::vector<Direction> ninetwofive = { Direction::RIGHT };
	EXPECT_EQ(bst.traverse(ninetwofive), 51);
	*/
}
