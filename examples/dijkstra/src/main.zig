//! Dijkstra Shortest Path
//!
//! An example using the module `ziggraph` to represent graphs.

const std = @import("std");
const ziggraph = @import("ziggraph");
const Graph = ziggraph.Graph;
const GraphType = ziggraph.GraphType;

/// Finds the minimum distance among the non visited nodes. Returns the
/// position of the node with the minimum distance from the source.
fn posMinDistance(visited: []const bool, distance: []const f64) ?usize {
    var minDistance = std.math.inf(f64);
    var pos: ?usize = null;
    for (0..visited.len) |i| {
        if (!visited[i] and distance[i] < minDistance) {
            pos = i;
            minDistance = distance[i];
        }
    }
    return pos;
}

pub fn main() !void {
    // Memory allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    
    // Graph declaration
    var g = Graph(u8).init(allocator, GraphType.Undirected);
    defer g.deinit();
    
    // Nodes initialization
    try g.addWeightedEdge(1, 2, 7.0);
    try g.addWeightedEdge(1, 3, 9.0);
    try g.addWeightedEdge(1, 6, 14.0);
    try g.addWeightedEdge(2, 3, 10.0);
    try g.addWeightedEdge(2, 4, 15.0);
    try g.addWeightedEdge(3, 4, 11.0);
    try g.addWeightedEdge(3, 6, 2.0);
    try g.addWeightedEdge(4, 5, 6.0);
    try g.addWeightedEdge(5, 6, 9.0);


    // List of nodes
    // TODO: use g.nodes(allocator)
    const nodes = [_]u8{1, 2, 3, 4, 5, 6};
    // Array representing visited nodes
    var visited = [_]bool{false} ** 6;
    // Array to store shortest distances
    var distance = [_]f64{std.math.inf(f64)} ** 6;
    // Array to store last visited node (adjacents)
    var last = [_]?u8{null} ** 6;
  
    // Initial values
    // The problem is to find the shortest path distance
    // taking as source the node 1
    const source: u8 = 1;
    const posSource = std.mem.indexOfScalar(u8, &nodes, source).?;
    distance[posSource] = 0;

    while (true) {
        // Not visited node with the minimum distance from source
        const posMin = posMinDistance(&visited, &distance) orelse break;
        // Marking this node as visited
        visited[posMin] = true;
        // Identified the current node
        const current = nodes[posMin];
        // Obtaning the list of neighbors
        const neighbors = try g.neighbors(allocator, current);
        defer allocator.free(neighbors);
        for (neighbors) |neighbor| {
            // For each neighbor, obtaning its position in arrays
            const posNgh = std.mem.indexOfScalar(u8, &nodes, neighbor).?; 
            if (visited[posNgh]) {
                continue;
            }
            // Distance from the source
            const alt = distance[posMin] + try g.weight(current, neighbor);
            // Updating distances and adjacent node
            if (alt < distance[posNgh]) {
                distance[posNgh] = alt;
                last[posNgh] = current;
            }
        }
    }
  
    // Output
    std.debug.print("Distances from node {d}:\n", .{source});
    std.debug.print("Node  Distance  Adjacent\n", .{});
    std.debug.print("------------------------\n", .{});
    for (0..visited.len) |i| {
        if (i == posSource) {
            continue;
        }
        std.debug.print("{d:>4}{d:>10}{d:>10}\n",
            .{nodes[i], distance[i], last[i].?});
    }
}
