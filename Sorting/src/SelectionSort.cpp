#include "SelectionSort.hpp"
#include <vector>

namespace selection
{
	std::vector<int> sort(std::vector<int> vectorToSort)
	{
		for (int current = 0; current < vectorToSort.size() - 1; current++)
		{
			int min = current;

			for (int i = current + 1; i < vectorToSort.size(); i++)
			{
				if (vectorToSort[i] < vectorToSort[min])
				{
					min = i;
				}
			}
			if (min != current)
			{
				int temp = vectorToSort[current];
				vectorToSort[current] = vectorToSort[min];
				vectorToSort[min] = temp;
			}
		}
		return vectorToSort;
	}

}

