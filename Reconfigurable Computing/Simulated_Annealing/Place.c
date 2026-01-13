// anneal.c
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>

// ---- runtime-configurable sizes (loaded from file) ----
static int GRID_X = 0;
static int GRID_Y = 0;
static int NUM_NODES = 0;
static int NUM_EDGES = 0;

// edges as a dynamic array of pairs
static int (*edges)[2] = NULL;

// annealing params (tweak as you like)
#define INITIAL_TEMPERATURE  10000.0f
#define COOLING_RATE         0.999f
#define STOP_THRESHOLD       0.0001f


typedef struct {
    int x;
    int y;
} Coord;

// --- prototypes ---
int  load_instance(const char *path, FILE *out);
void free_instance(void);

void anneal(Coord *current, FILE *out);
void copy_coords(const Coord *src, Coord *dst);
void neighbor(Coord *state);                    // generate a neighbor state
int  evaluate(const Coord *placement);
void accept_move(int *current_val, int next_val, Coord *current, const Coord *next, float temperature);

// helpers for neighbor generation
static inline int cell_index(int x, int y) { return y * GRID_X + x; }
int  is_occupied(const Coord *placement, int n_nodes, int x, int y);

//-----------------------------------------------------
int main(int argc, char **argv) {
    if (argc < 3) {
        fprintf(stderr, "Usage: %s <input_file> <output_file>\n", argv[0]);
        return 1;
    }

    const char *inputFile  = argv[1];
    const char *outputFile = argv[2];

    FILE *out = fopen(outputFile, "w");
    if (!out) {
        perror("Error opening output file");
        return 1;
    }

    if (load_instance(inputFile, out) != 0) {
        fprintf(stderr, "Failed to load instance from '%s'\n", inputFile);
        fclose(out);
        return 1;
    }

    Coord *current = (Coord *)malloc(NUM_NODES * sizeof(*current));
    if (!current) {
        perror("malloc current");
        free_instance();
        fclose(out);
        return 1;
    }

    // Initialize placement (row-major fill of the first NUM_NODES cells)
    int idx = 0;
    for (int y = 0; y < GRID_Y && idx < NUM_NODES; y++) {
        for (int x = 0; x < GRID_X && idx < NUM_NODES; x++) {
            current[idx].x = x;
            current[idx].y = y;
            idx++;
        }
    }

    fprintf(out, "Grid size: %d x %d\n", GRID_X, GRID_Y);
    fprintf(out, "Nodes: %d\n", NUM_NODES);
    fprintf(out, "Edges: %d\n\n", NUM_EDGES);

    fprintf(out, "Initial placement:\n");
    for (int i = 0; i < NUM_NODES; i++)
        fprintf(out, "Node %d at (%d,%d)\n", i, current[i].x, current[i].y);

    srand((unsigned)time(NULL));
    anneal(current, out);

    fprintf(out, "\nFinal placement:\n");
    for (int i = 0; i < NUM_NODES; i++)
        fprintf(out, "Node %d placed at (%d,%d)\n", i, current[i].x, current[i].y);

    fprintf(out, "\nEdge Lengths:\n");
    for (int e = 0; e < NUM_EDGES; e++) {
        int u = edges[e][0];
        int v = edges[e][1];
        int length = abs(current[u].x - current[v].x) +
                     abs(current[u].y - current[v].y);
        fprintf(out, "Edge %d: %d to %d has length %d\n", e, u, v, length);
    }

    free(current);
    free_instance();
    fclose(out);
    return 0;
}

//-----------------------------------------------------
// INPUT:  lines like
// g <rows> <cols>
// v <num_nodes>
// e <u> <v>
//-----------------------------------------------------
int load_instance(const char *path, FILE *out) {
    FILE *fp = fopen(path, "r");
    if (!fp) { perror("fopen"); return -1; }

    char tag;
    int rows, cols, n;
    int cap = 0; // capacity for edges
    NUM_EDGES = 0;

    while (fscanf(fp, " %c", &tag) == 1) {
        if (tag == 'g') {
            if (fscanf(fp, "%d %d", &rows, &cols) != 2) { fclose(fp); return -1; }
            GRID_Y = rows;  // rows first in file
            GRID_X = cols;  // then cols
        } else if (tag == 'v') {
            if (fscanf(fp, "%d", &n) != 1) { fclose(fp); return -1; }
            NUM_NODES = n;
        } else if (tag == 'e') {
            int u, v;
            if (fscanf(fp, "%d %d", &u, &v) != 2) { fclose(fp); return -1; }
            if (NUM_EDGES == cap) {
                cap = cap ? cap * 2 : 16;
                int (*new_edges)[2] = realloc(edges, cap * sizeof(*edges));
                if (!new_edges) { perror("realloc"); fclose(fp); return -1; }
                edges = new_edges;
            }
            edges[NUM_EDGES][0] = u;
            edges[NUM_EDGES][1] = v;
            NUM_EDGES++;
        } else {
            // skip rest of line for unknown tags/comments
            int c;
            while ((c = fgetc(fp)) != '\n' && c != EOF) {}
        }
    }

    fclose(fp);

    if (GRID_X <= 0 || GRID_Y <= 0 || NUM_NODES <= 0) {
        if (out) fprintf(out, "Invalid or incomplete instance (need g and v lines)\n");
        return -1;
    }

    // Optional: basic validation
    int bad = 0;
    for (int i = 0; i < NUM_EDGES; i++) {
        if (edges[i][0] < 0 || edges[i][0] >= NUM_NODES ||
            edges[i][1] < 0 || edges[i][1] >= NUM_NODES) {
            bad++;
        }
    }
    if (bad && out) fprintf(out, "Warning: %d edge(s) reference invalid node indices\n", bad);

    return 0;
}

void free_instance(void) {
    free(edges);
    edges = NULL;
}

//-----------------------------------------------------
void anneal(Coord *current, FILE *out) {
    float temperature = INITIAL_TEMPERATURE;
    int current_val = evaluate(current);

    Coord *next = (Coord *)malloc(NUM_NODES * sizeof(*next));
    if (!next) { perror("malloc next"); return; }

    long long iterations = 0;
    if (out) fprintf(out, "\nInitial score: %d\n", current_val);

    while (temperature > STOP_THRESHOLD) {
        copy_coords(current, next);
        neighbor(next);                       // generate a valid neighbor
        int next_val = evaluate(next);
        accept_move(&current_val, next_val, current, next, temperature);

        temperature *= COOLING_RATE;
        iterations++;
    }

    if (out) {
        fprintf(out, "\nExplored %lld solutions\n", iterations);
        fprintf(out, "Final score: %d\n", current_val);
    }

    free(next);
}

//-----------------------------------------------------
void copy_coords(const Coord *src, Coord *dst) {
    for (int i = 0; i < NUM_NODES; i++) dst[i] = src[i];
}

// Generate a neighbor state by either:
//  - swapping two nodes, or
//  - moving one node to a random EMPTY cell anywhere on the grid.
void neighbor(Coord *state) {
    int move_type = rand() & 1; // 0 = swap, 1 = move to empty

    if (move_type == 0 || GRID_X * GRID_Y == NUM_NODES) {
        // SWAP two nodes
        int a, b;
        do {
            a = rand() % NUM_NODES;
            b = rand() % NUM_NODES;
        } while (a == b);
        Coord t = state[a];
        state[a] = state[b];
        state[b] = t;
    } else {
        // MOVE one node to a random EMPTY cell
        int n = rand() % NUM_NODES;

        // Try a reasonable number of times to find an empty target
        for (int tries = 0; tries < 256; tries++) {
            int rx = rand() % GRID_X;
            int ry = rand() % GRID_Y;

            // skip if the selected cell is already occupied in 'state'
            if (!is_occupied(state, NUM_NODES, rx, ry)) {
                state[n].x = rx;
                state[n].y = ry;
                return;
            }
        }

        // Fallback: if we couldn't find an empty quickly (very dense), swap instead
        int a, b;
        do { a = rand() % NUM_NODES; b = rand() % NUM_NODES; } while (a == b);
        Coord t = state[a]; state[a] = state[b]; state[b] = t;
    }
}

int is_occupied(const Coord *placement, int n_nodes, int x, int y) {
    for (int i = 0; i < n_nodes; i++) {
        if (placement[i].x == x && placement[i].y == y) return 1;
    }
    return 0;
}

//-----------------------------------------------------
int evaluate(const Coord *placement) {
    int total = 0;
    for (int e = 0; e < NUM_EDGES; e++) {
        int u = edges[e][0];
        int v = edges[e][1];
        total += abs(placement[u].x - placement[v].x) +
                 abs(placement[u].y - placement[v].y);
    }
    return total;
}

//-----------------------------------------------------
void accept_move(int *current_val, int next_val, Coord *current, const Coord *next, float temperature) {
    int delta = next_val - *current_val;
    if (delta <= 0) {
        for (int i = 0; i < NUM_NODES; i++) current[i] = next[i];
        *current_val = next_val;
    } else {
        float p = expf(-(float)delta / temperature);
        float r = (float)rand() / (float)RAND_MAX;
        if (r < p) {
            for (int i = 0; i < NUM_NODES; i++) current[i] = next[i];
            *current_val = next_val;
        }
    }
}
