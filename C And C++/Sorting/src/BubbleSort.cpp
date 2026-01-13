#include "BubbleSort.hpp"
#include <vector>


namespace bubble
{
	std::vector<int> sort(std::vector<int> vectorToSort)
	{
		int i, j, temp;

		for (i = 0; i < vectorToSort.size() - 1; i++)
		{
			for (j = 0; j < vectorToSort.size() - i - 1; j++)
			{
				if (vectorToSort[j] > vectorToSort[j + 1])
				{
					temp = vectorToSort[j];
					vectorToSort[j] = vectorToSort[j + 1];
					vectorToSort[j + 1] = temp;
				}
			}
		}
		return vectorToSort;
	}

}