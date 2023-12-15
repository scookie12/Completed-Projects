#ifndef DOUBLY_LINKED_LIST_HPP
#define DOUBLY_LINKED_LIST_HPP

#include <memory>
#include <stdexcept>

template <typename T>
class DoublyLinkedList
{
public:
    DoublyLinkedList<T>()
    {
        head = nullptr; 
        tail = nullptr;
    }

    void create(T value)
    {
        //auto new_node = std::make_shared<Node<T>>(new Node<T>);
        std::shared_ptr<Node<T>> new_node(new Node<T>);
        new_node->value = value;

        new_node->next = nullptr;
        auto temp = head;

        if (head == nullptr) {
            new_node->prev = nullptr;
            head = new_node;
            m_count++;
            return;
        }

        while (temp->next != NULL)
            temp = temp->next;

        temp->next = new_node;

        new_node->prev = temp;

        m_count++;
    }

    T retreive(T value)
    {
        auto temp = head;
        while (temp != nullptr)
        {
            if (temp->value == value)
                return temp->value;

            temp = temp->next;
        }

        throw std::runtime_error("Value not found in list");
    }

    void update(T oldValue, T newValue)
    {
        auto temp = head;
        
        while (temp != nullptr)
        {
            if (temp->value == oldValue)
            {
                temp->value = newValue;
                return;
            }

            temp = temp->next;
            
        }
        throw std::runtime_error("Old Value not found in list");
    }

    void remove(T value)
    {
        auto temp = head;
        while (temp != nullptr)
        {
            if (temp->value == value && temp->prev == nullptr)
            {
                temp->next->prev = temp->prev;
                head = temp->next;

                m_count--;

                return;
            }
            else if (temp->value == value && temp->next == nullptr)
            {
                temp->prev->next = temp->next;
                tail = temp->prev;

                m_count--;

                return;

            } else if (temp -> value == value)
            {
                temp->prev->next = temp->next;
                temp->next->prev = temp->prev;

                m_count--;

                return;
            }

            temp = temp->next;
        }
        throw std::runtime_error("Value not found in list");
    }


    size_t size()
    {
        return m_count;
    }

private:
    template <typename T2>
    struct Node {
        T2 value;
        std::shared_ptr<Node<T2>> next;
        std::shared_ptr<Node<T2>> prev;
    };

    std::shared_ptr<Node<T>> head;
    std::shared_ptr<Node<T>> tail;

    size_t m_count = 0;
};

#endif

