# ziggraph - A graph library written in Zig

Here is an example:

```zig
const std = @import("std");
const graph = @import("src/graph.zig");
const Graph = graph.Graph;
const GraphType = graph.GraphType;

const City = enum {
    NEW_YORK,
    LOS_ANGELES,
    CHICAGO,
    HOUSTON,
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var g = try Graph(City).init(allocator, GraphType.Undirected);
    defer g.deinit();

    try g.addWeightedEdge(.NEW_YORK, .LOS_ANGELES, 2448.15);
    try g.addWeightedEdge(.NEW_YORK, .CHICAGO, 714.82);
    try g.addWeightedEdge(.LOS_ANGELES, .HOUSTON, 1370.93); 

    const edges = try g.getEdges(allocator);
    defer allocator.free(edges);

    for (edges) |edge| {
        const distance = try g.getWeight(edge.node_a, edge.node_b); 
        std.debug.print("{s} - {s}: {} miles\n", .{
            @tagName(edge.node_a),
            @tagName(edge.node_b),
            distance.?,
        });
    }
}
```
