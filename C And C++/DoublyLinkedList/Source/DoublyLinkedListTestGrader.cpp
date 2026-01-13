
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