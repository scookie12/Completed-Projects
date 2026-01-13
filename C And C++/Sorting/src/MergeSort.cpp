#include "MergeSort.hpp"
#include <vector>
#include <iostream>

namespace merge
{

	std::vector<int> mergeVectors (std::vector<int> leftVector, std::vector<int> rightVector) {
		size_t n1 = 0;
		size_t n2 = 0;

		std::vector<int> merged;
		while (n1 < leftVector.size() && n2 < rightVector.size())
			// Find which value in the vector is greater, put that in the merged vector
			if (leftVector[n1] < rightVector[n2])
				merged.push_back(leftVector[n1++]);
			else
				merged.push_back(rightVector[n2++]);
		
		while (n1 < leftVector.size()) // more values in left than right vector
			merged.push_back(leftVector[n1++]);
		
		while (n2 < rightVector.size()) // more values in right than left vector
			merged.push_back(rightVector[n2++]);

		return merged;
	}

	std::vector<int> sort(std::vector<int> vectorToSort) {
		if (vectorToSort.size() <= 1) // if size is 1 or 0
			return vectorToSort;

		size_t halfway = vectorToSort.size() / 2; // get the midpoint of the main vector

		std::vector<int> left(vectorToSort.begin(), vectorToSort.begin() + halfway); // create left vector

		std::vector<int> right(vectorToSort.begin() + halfway, vectorToSort.end()); // create right vector

		return mergeVectors(sort(left), sort(right)); // return the sorted vector that mergeVectors creates
	}

}