
cmake_minimum_required(VERSION 3.0)
set(CMAKE_INSTALL_PREFIX ${CMAKE_BINARY_DIR})
if(WIN32) 
  add_compile_options(/W4 /WX) 
else() 
  add_compile_options(-Wall -Wextra -Wpedantic -Werror) 
endif()
project(Sorting)
add_library(SortingLib STATIC
  BubbleSort.hpp
  MergeSort.hpp
  SelectionSort.hpp
  BubbleSort.cpp
  MergeSort.cpp
  SelectionSort.cpp
  )
set_target_properties(SortingLib PROPERTIES LINKER_LANGUAGE CXX)
include(FetchContent)
FetchContent_Declare(
  googletest
  URL https://github.com/google/googletest/archive/609281088cfefc76f9d0ce82e1ff6c30cc3591e5.zip
  )
# For Windows: Prevent overriding the parent project's compiler/linker settings
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(googletest)
enable_testing()
add_executable(SortTest
  BigVector.hpp
  SortTestGiven.cpp
  SortTestOwn.cpp
  SortTestGrader.cpp
  )
target_link_libraries(SortTest PUBLIC SortingLib gtest_main)
install(TARGETS SortTest DESTINATION "dist")
include(GoogleTest)
gtest_discover_tests(SortTest)