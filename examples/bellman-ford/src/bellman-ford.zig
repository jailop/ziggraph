const std = @import("std");
const graph = @import("./graph.zip");
const Graph = graph.Graph;
const GraphType = graph.GraphType;

test "Bellman-Ford" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var g = Graph(u8).init(allocator, GraphType.Directed);
    defer g.deinit();

    try g.addEdges([_]struct{u8, u8, f64}{
        .{'A', 'B', 5.0},
        .{'B', 'C', 1.0},
        .{'B', 'D', 2.0},
        .{'C', 'E', 1.0},
        .{'D', 'E', -1.0},
        .{'D', 'F', 2.0},
        .{'E', 'F', -3.0},
    });
}
