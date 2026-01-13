#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#include <string>
#include <cstdlib>
#include <cmath>
#include <ctime>
#include <set>
#include <chrono>

struct Node {
    int id;
    int x, y;
};

struct Edge {
    int src, dst;
};

int grid_x, grid_y;
std::vector<Node> nodes;
std::vector<Edge> edges;

// Manhattan distance
int manhattan(int x1, int y1, int x2, int y2) {
    return std::abs(x1 - x2) + std::abs(y1 - y2);
}

// Evaluate cost: the maximum (longest) edge length
int cost_longest_edge(const std::vector<Node>& nodes, const std::vector<Edge>& edges) {
    int max_len = 0;
    for (auto &e : edges) {
        int L = manhattan(
            nodes[e.src].x, nodes[e.src].y,
            nodes[e.dst].x, nodes[e.dst].y
        );
        if (L > max_len) max_len = L;
    }
    return max_len;
}

// Neighbor generation: swap or move
std::vector<Node> neighbour(const std::vector<Node>& curr) {
    std::vector<Node> next = curr;
    int choice = rand() % 2;

    if (choice == 0) {
        // swap two nodes
        int i = rand() % next.size();
        int j = rand() % next.size();
        std::swap(next[i].x, next[j].x);
        std::swap(next[i].y, next[j].y);
    } else {
        // move one node to random position
        int i = rand() % next.size();
        next[i].x = rand() % grid_x;
        next[i].y = rand() % grid_y;
    }

    return next;
}

// Simulated annealing loop using threshold stop
std::vector<Node> simulated_annealing(std::vector<Node> s0, double T0, double alpha, double stop_T) {
    std::vector<Node> s = s0;
    int cost_s = cost_longest_edge(s, edges);
    std::vector<Node> best = s;
    int best_cost = cost_s;

    double T = T0;
    while (T > stop_T) {
        std::vector<Node> s_next = neighbour(s);
        int cost_next = cost_longest_edge(s_next, edges);
        int dE = cost_s - cost_next;

        if (dE > 0 || exp(dE / T) > ((double) rand() / RAND_MAX)) {
            s = s_next;
            cost_s = cost_next;
            if (cost_s < best_cost) {
                best = s;
                best_cost = cost_s;
            }
        }

        T *= alpha; // geometric cooling
    }

    return best;
}

// Input parsing
void parse_input(const std::string &filename) {
    std::ifstream infile(filename);
    if (!infile) {
        std::cerr << "Error: Cannot open input file " << filename << std::endl;
        exit(1);
    }

    std::string line;
    int num_nodes = 0;

    while (std::getline(infile, line)) {
        std::stringstream ss(line);
        char type;
        ss >> type;

        if (type == 'g') {
            ss >> grid_x >> grid_y;
        } else if (type == 'v') {
            ss >> num_nodes;
            nodes.resize(num_nodes);
            for (int i = 0; i < num_nodes; i++) {
                nodes[i] = {i, -1, -1}; // placeholder coords
            }
        } else if (type == 'e') {
            int a, b;
            ss >> a >> b;
            edges.push_back({a, b});
        }
    }
}

// Output writing
void write_output(const std::string &filename, const std::vector<Node>& placed) {
    std::ofstream outfile(filename);
    if (!outfile) {
        std::cerr << "Error: Cannot open output file " << filename << std::endl;
        exit(1);
    }

    for (auto &n : placed) {
        outfile << "Node " << n.id << " placed at (" << n.x << ", " << n.y << ")\n";
    }
    outfile << "\n";

    for (auto &e : edges) {
        int L = manhattan(
            placed[e.src].x, placed[e.src].y,
            placed[e.dst].x, placed[e.dst].y
        );
        outfile << "Edge from " << e.src << " to " << e.dst << " has length " << L << "\n";
    }
}

int main(int argc, char* argv[]) {
    if (argc != 3) {
        std::cerr << "Usage: ./place input.txt output.txt\n";
        return 1;
    }

    std::string input_file = argv[1];
    std::string output_file = argv[2];

    srand(time(nullptr));

    parse_input(input_file);

    // Initial random placement
    std::set<std::pair<int,int>> used;
    for (auto &n : nodes) {
        int x, y;
        do {
            x = rand() % grid_x;
            y = rand() % grid_y;
        } while (used.count({x,y}));
        n.x = x;
        n.y = y;
        used.insert({x,y});
    }

    // Parameters (tune these!)
    double T0 = 10000.0;    // initial temperature
    double alpha = 0.999;   // cooling rate
    double stop_T = 0.0001; // stopping threshold

    auto start = std::chrono::high_resolution_clock::now();
    std::vector<Node> best = simulated_annealing(nodes, T0, alpha, stop_T);
    auto end = std::chrono::high_resolution_clock::now();

    double runtime = std::chrono::duration<double>(end - start).count();
    std::cout << "Finished SA. Runtime: " << runtime << " seconds.\n";

    write_output(output_file, best);

    return 0;
}
