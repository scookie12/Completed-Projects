#ifndef BST_HPP
#define BST_HPP

enum class Direction
{
	LEFT,
	RIGHT
};

template <typename Key, typename Value>
class Bst
{
	struct treeNode
	{
		treeNode(Key key, Value value) : key(key), value(value), right(nullptr), left(nullptr)
		{}
		Key key;
		Value value;
		std::shared_ptr <treeNode> right;
		std::shared_ptr <treeNode> left;
	};
	
public:
	Bst() : m_treesize(0), head(nullptr) // time complexity O(1)
	{
		
	}

	Bst(Bst const& bst) // time complexity O(N)
	{
		head = nullptr;
		m_treesize = bst.m_treesize;
		recurcop(bst.head, head);
	}

	void recurcop(std::shared_ptr<treeNode> const& old, std::shared_ptr<treeNode>& newnode)
	{
		if (old != nullptr)
		{
			newnode = std::make_shared <treeNode>(old->key, old->value);
			recurcop(old->left, newnode->left);
			recurcop(old->right, newnode->right);
		}
	}

	void add(Key const& key, Value const& value) // time complexity 0(N)
	{
		auto notor = std::make_shared <treeNode> (key, value);
		
		if (head == nullptr) {
			head = notor; 
			m_treesize++;
			return;
		}
			recursiveAdd(head, notor);
	}

	void recursiveAdd(std::shared_ptr<treeNode> OG, std::shared_ptr <treeNode> young_blood)
	{
		if (young_blood->key == OG->key)
		{
			return;
		}
		else if (young_blood->key < OG->key)
		{
			if (OG->left != nullptr)
				recursiveAdd(OG->left, young_blood);
			else
			{
				OG->left = young_blood;
				m_treesize++;
				return;
			}
		}
		else if (young_blood->key > OG->key)
		{
			if (OG->right != nullptr)
				recursiveAdd(OG->right, young_blood);
			else
			{
				OG->right = young_blood;
				m_treesize++;
				return;
			}
		}
	}

	void update(Key const& key, Value const& value) // time complexity o(N)
	{
		std::shared_ptr<treeNode> tree = head;
		while (tree != nullptr)
		{
			if (tree->key == key) {
				tree->value = value;
				return;
			}
			else if (key < tree->key)
				tree = tree->left;
			else
				tree = tree->right;
		}
			throw std::runtime_error("Key could not be updated");
	}

	void remove(Key const& key) // time complexity O(N)
	{
		auto tree = head;
		remove(tree, key);

	}

	void remove(std::shared_ptr<treeNode> tree, Key const& key)
	{
		if (tree == nullptr)
			throw std::runtime_error("Node could not be removed");
		else if (key < tree->key)
			remove(tree->left, key);
		else if (key > tree->key)
			remove(tree->right, key);
		else
			makeDeletion(tree);
	}

	void makeDeletion(std::shared_ptr <treeNode> tree)
	{
		std::shared_ptr<treeNode> deletenode = tree;
		std::shared_ptr<treeNode> attach;
		if (tree->right == nullptr && tree->left == nullptr)
		{
			tree = nullptr;
		}
		else if (tree->right == nullptr)
		{
			tree->value = tree->left->value;
			tree-> key = tree->left->key;
			tree->left = nullptr;
		} 
		else if (tree->left == nullptr)
		{
			tree->value = tree->right->value;
			tree->key = tree->right->key;
			tree->right = nullptr;
		} 
		else
		{
			attach = tree->left;
			while (attach->right != nullptr)
			{
				attach = attach->right;
			}
				tree->value = attach->value;
				tree->key = attach->key;
			while (attach->left != nullptr)
			{
				attach->value = attach->left->value;
				attach->key = attach->right->key;
				attach = attach->right;
			}
		}
		deletenode = nullptr;
		--m_treesize;
	}

	Value& at(Key const& key) // time complexity O(N)
	{
		std::shared_ptr<treeNode> tree = head;
		while (tree != nullptr)
		{
			if (tree->key == key)
				return tree->value;
			else if (key < tree->key)
				tree = tree->left;
			else
				tree = tree->right;
		}
			throw std::runtime_error("Key could not be retrieved");
	}

	Value& operator[](Key const& key) // time complexity O(N)
	{
		return at(key);
	}

	Value traverse(std::vector<Direction> const& path) // time complexity O(N)
	{ 
		std::shared_ptr<treeNode> goneinaflash = head;
		size_t j = path.size();
		for (size_t i = 0; i < j; i++)
		{
			if (path[i] == Direction::LEFT)
			{
				if (goneinaflash->left != nullptr)
					goneinaflash = goneinaflash->left;
				else 
					throw std::runtime_error("No result at the end of path");
					
			}
			else if (path[i] == Direction::RIGHT)
			{
				if (goneinaflash->right != nullptr)
					goneinaflash = goneinaflash->right;
				else
					throw std::runtime_error("No result at the end of path");
					
			}
				
		}
		return goneinaflash->value;
		
	}

	size_t size() // time complexity O(1)
	{
		return this -> m_treesize;
	}

private:
	size_t m_treesize;
	
	std::shared_ptr <treeNode> head;
	
};

#endif

	