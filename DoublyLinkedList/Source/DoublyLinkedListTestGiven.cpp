
#include <gtest/gtest.h>

#include "DoublyLinkedList.hpp"

struct TestStruct
{
    std::string key;
    std::string value;
    bool operator==(TestStruct const& other)
    {
        return key == other.key;
    }
};

TEST(GivenWrittenTests, CreateRetreiveInt)
{
    DoublyLinkedList<int> list;
    list.create(4);
    list.create(3);
    list.create(2);
    EXPECT_EQ(list.size(), 3);

    EXPECT_EQ(list.retreive(4), 4);
    EXPECT_EQ(list.retreive(3), 3);
    EXPECT_EQ(list.retreive(2), 2);
    EXPECT_THROW(list.retreive(1), std::runtime_error);
}

TEST(GivenWrittenTests, CreateRetreiveStruct)
{
    DoublyLinkedList<TestStruct> list;
    list.create(TestStruct{ "a", "a" });
    list.create(TestStruct{ "b", "a" });
    list.create(TestStruct{ "c", "c" });
    EXPECT_EQ(list.size(), 3);

    EXPECT_EQ(list.retreive(TestStruct{ "a", "" }).value, "a");
    EXPECT_EQ(list.retreive(TestStruct{ "b", "" }).value, "a");
    EXPECT_EQ(list.retreive(TestStruct{ "c", "" }).value, "c");
}
