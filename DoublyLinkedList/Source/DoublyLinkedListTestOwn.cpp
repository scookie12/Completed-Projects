
#include <gtest/gtest.h>

#include "DoublyLinkedList.hpp"

TEST(DoublyLinkedListTest, createupdateretrieve)
{
    DoublyLinkedList<int> list;
    list.create(4);
    list.create(3);
    list.create(2);
    list.update(4, 1);
    list.update(2, 5);
    EXPECT_EQ(list.size(), 3);

    EXPECT_EQ(list.retreive(3), 3);
    EXPECT_EQ(list.retreive(1), 1);
    EXPECT_EQ(list.retreive(5), 5);
    EXPECT_THROW(list.retreive(4), std::runtime_error);
}

TEST(DoublyLinkedListTest, createremove)
{
    DoublyLinkedList<int> list;
    list.create(4);
    list.create(3);
    list.create(2);
    list.remove(4);
    list.remove(2);
    EXPECT_EQ(list.size(), 1);
    EXPECT_THROW(list.remove(6), std::runtime_error);

    EXPECT_EQ(list.retreive(3), 3);
    EXPECT_THROW(list.retreive(4), std::runtime_error);
}