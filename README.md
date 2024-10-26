# ziggraph - A graph representation module written in Zig

This module is intended to provide a representation for graph basic
operations. It does not implement graph algorithms.

Documentation: <https://jailop.github.io/ziggraph/>

Example:

```zig
const std = @import("std");
const graph = @import("ziggraph");
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

    const edges = try g.edges(allocator);
    defer allocator.free(edges);

    for (edges) |edge| {
        const distance = try g.weight(edge.node_a, edge.node_b); 
        std.debug.print("{s} - {s}: {} miles\n", .{
            @tagName(edge.node_a),
            @tagName(edge.node_b),
            distance.?,
        });
    }
}
```

The output is:

```
LOS_ANGELES - NEW_YORK: 2.44815e3 miles
LOS_ANGELES - HOUSTON: 1.37093e3 miles
NEW_YORK - LOS_ANGELES: 2.44815e3 miles
NEW_YORK - CHICAGO: 7.1482e2 miles
CHICAGO - NEW_YORK: 7.1482e2 miles
HOUSTON - LOS_ANGELES: 1.37093e3 miles
```

To include this module in your project, declare it as a dependency in the
`build.zig.zon` file:

```zig
    ...
    .dependencies = .{                                                          
        ...
        .ziggraph = .{                                                           
            .url = "https://github.com/jailop/ziggraph/archive/refs/tags/ziggraph-0.1.1.tar.gz",                                                                
            .hash = "122047dc37aacfe81d401438830104c1e0c4aa47da33eb830456063d9da27d82d876",                                                                     
        },
        ...
    },
    ...
```

After that, import the module for your executable artifact in `build.zig`. For
example:

```zig
   const exe = b.addExecutable(.{                                              
        .name = "MyExecutable",                                                           
        .root_source_file = b.path("src/main.zig"),
        .target = target,                                                       
        .optimize = optimize,                                                   
    });                                                                         
                                                                                
    const ziggraph = b.dependency("ziggraph", .{                                
        .target = target,                                                       
        .optimize = optimize,                                                   
    });                                                                         
                                                                                
    exe.root_module.addImport("ziggraph", ziggraph.module("ziggraph"));    
    
    b.installArtifact(exe);
```
