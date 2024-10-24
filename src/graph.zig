//! A basic Graph type to use with Zig's primitive types

const std = @import("std");

/// A graph can be directed
/// or undirected. When you create a new
/// graph, it is required to specify its
/// type.
pub const GraphType = enum {
    /// Edges have direction. Every edge goes from one
    /// note to another, but not backwards.
    Directed,
    /// Edges have not direction.
    Undirected,
};

pub const GraphError = error{
    /// Returned when a duplicated node is tried to be added.
    NodeAlreadyExists,
    /// Returned when querying properties of a not existing node.
    NodeNotExists,
    /// Returned when a duplicated edge is tried to be added.
    EdgeAlreadyExists,
    /// Returned when querying properties of a not existing edge.
    EdgeNotExists,
    /// Returned when there is not connection between two nodes.
    PathNotExists,
    /// Returned when functions speficif for a type of graph are called.
    /// For example, inDegree and outDegree only work with directed
    /// graphs.
    IncorrectGraphType,
};

/// Represents a set of node and a set of edges connecting nodes. Data type to
/// be used to represent nodes shoudl be specified when the graph is
/// initialized. You can use any scalar type working with logical opertors.
pub fn Graph(comptime T: type) type {
    return struct {
        const Node = struct {
            adjs: std.ArrayList(T),
            weights: std.ArrayList(?f64),
        };

        pub const Edge = struct {
            node_a: T,
            node_b: T,
        };

        const Self = @This();
        nodes: std.ArrayList(T),
        root: std.ArrayList(Node),
        allocator: std.mem.Allocator,
        gType: GraphType,

        pub fn init(allocator: std.mem.Allocator, comptime gType: GraphType) !Self {
            return Self{
                .nodes = std.ArrayList(T).init(allocator),
                .root = std.ArrayList(Node).init(allocator),
                .gType = gType,
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *const Self) void {
            for (self.root.items) |vertex| {
                vertex.adjs.deinit();
                vertex.weights.deinit();
            }
            self.nodes.deinit();
            self.root.deinit();
        }

        inline fn getNodeIndex(self: *const Self, vertex: T) ?usize {
            return std.mem.indexOfScalar(T, self.nodes.items, vertex);
        }

        pub fn hasNode(self: *const Self, vertex: T) bool {
            const value = self.getNodeIndex(vertex);
            return if (value) |_| true else false;
        }

        pub fn hasEdge(self: *Self, node_a: T, node_b: T) bool {
            const node = self.getNode(node_a);
            if (node) |n| {
                for (n.adjs.items) |vertex| {
                    if (vertex == node_b) {
                        return true;
                    }
                }
            }
            return false;
        }

        pub fn addNode(self: *Self, vertex: T) !void {
            if (self.hasNode(vertex)) {
                return GraphError.NodeAlreadyExists;
            }
            try self.nodes.append(vertex);
            try self.root.append(Node{
                .adjs = std.ArrayList(T).init(self.allocator),
                .weights = std.ArrayList(?f64).init(self.allocator),
            });
        }

        pub fn addNodesFrom(self: *Self, vertices: []T) !void {
            for (vertices) |vertex| {
                try self.addNode(vertex);
            }
        }

        fn getNode(self: *Self, vertex: T) ?*Node {
            for (0..self.nodes.items.len) |i| {
                if (self.nodes.items[i] == vertex) {
                    return &self.root.items[i];
                }
            }
            return null;
        }

        fn _addEdge(self: *Self, node_a: T, node_b: T, weight: ?f64) !void {
            if (!self.hasNode(node_b)) {
                try self.addNode(node_b);
            }
            if (!self.hasNode(node_a)) {
                try self.addNode(node_a);
            }
            const node = self.getNode(node_a);
            if (node) |n| {
                for (n.adjs.items) |vertex| {
                    if (vertex == node_b) {
                        return GraphError.EdgeAlreadyExists;
                    }
                }
                try n.adjs.append(node_b);
                try n.weights.append(weight);
            }
        }

        pub fn addWeightedEdge(self: *Self, node_a: T, node_b: T, weight: ?f64) !void {
            try self._addEdge(node_a, node_b, weight);
            if (self.gType == GraphType.Undirected) {
                try self._addEdge(node_b, node_a, weight);
            }
        }

        pub fn addEdge(self: *Self, node_a: T, node_b: T) !void {
            try self.addWeightedEdge(node_a, node_b, undefined);
        }

        pub fn numberOfNodes(self: *const Self) u64 {
            return self.root.items.len;
        }

        pub fn numberOfEdges(self: *const Self) u64 {
            var count: u64 = 0;
            for (self.root.items) |node| {
                count += node.adjs.items.len;
            }
            return if (self.gType == GraphType.Directed) count else count / 2;
        }

        pub fn getWeight(self: *Self, node_a: T, node_b: T) !?f64 {
            const node = self.getNode(node_a);
            if (node) |n| {
                for (0..n.adjs.items.len) |i| {
                    if (n.adjs.items[i] == node_b) {
                        return n.weights.items[i];
                    }
                }
            }
            return GraphError.EdgeNotExists;
        }

        pub fn getSuccesors(self: *Self, allocator: std.mem.Allocator, vertex: T) ![]T {
            const node = self.getNode(vertex);
            if (node) |n| {
                const res = try allocator.alloc(T, n.adjs.items.len);
                std.mem.copyForwards(T, res, n.adjs.items);
                return res;
            }
            return GraphError.NodeNotExists;
        }

        /// Returns the number of edges out of a node
        pub fn outDegree(self: *Self, node: T) !usize {
            if (self.gType != GraphType.Directed) {
                return GraphError.IncorrectGraphType;
            }
            const node_ = self.getNode(node);
            if (node_) |n| {
                return n.adjs.items.len;
            }
            return GraphError.NodeNotExists;
        }

        /// Returns a list of vertex that are predecessor of the required one.
        /// If the required vertex doesn't exist, an error is returned.
        /// If the required vertex doesn't have any predecessor, a empty list
        /// is returned.
        pub fn getPredecessors(self: *Self, allocator: std.mem.Allocator, vertex: T) ![]T {
            if (!self.hasNode(vertex)) {
                return GraphError.NodeNotExists;
            }
            var pred = std.ArrayList(T).init(self.allocator);
            defer pred.deinit();
            for (0..self.root.items.len) |i| {
                for (self.root.items[i].adjs.items) |v| {
                    if (vertex == v) {
                        try pred.append(self.nodes.items[i]);
                    }
                }
            }
            const res = try allocator.alloc(T, pred.items.len);
            std.mem.copyForwards(T, res, pred.items);
            return res;
        }
       
        // Returns the number of edges in of a node
        pub fn inDegree(self: *Self, node: T) !usize {
            if (self.gType != GraphType.Directed) {
                return GraphError.IncorrectGraphType;
            }
            if (!self.hasNode(node)) {
                return GraphError.NodeNotExists;
            }
            var counter : usize = 0;
            for (0..self.root.items.len) |i| {
                for (self.root.items[i].adjs.items) |v| {
                    if (node == v) {
                        counter += 1;
                    }
                }
            }
            return counter;
        }

        /// Returns the list of edges defined in the graph.
        pub fn getEdges(self: *Self, allocator: std.mem.Allocator) ![]Self.Edge {
            var edges = std.ArrayList(Self.Edge).init(self.allocator);
            defer edges.deinit();
            for (0..self.root.items.len) |i| {
                for (self.root.items[i].adjs.items) |vertex| {
                    try edges.append(Self.Edge{
                        .node_a = self.nodes.items[i],
                        .node_b = vertex,
                    });
                }
            }
            const res = try allocator.alloc(Self.Edge, edges.items.len);
            std.mem.copyForwards(Self.Edge, res, edges.items);
            return res;
        }
    };
}

test "GraphAddingNodes" {
    var g = try Graph(u32).init(std.testing.allocator, GraphType.Directed);
    defer g.deinit();
    try g.addNode(0);
    try std.testing.expect(g.hasNode(0));
    var x = [_]u32{ 1, 2, 3, 4, 5 };
    try g.addNodesFrom(&x);
    for (x) |value| {
        try std.testing.expect(g.hasNode(value));
    }
    try std.testing.expect(!g.hasNode(10));
}

test "GraphAddingEdges" {
    var g = try Graph(u16).init(std.testing.allocator, GraphType.Undirected);
    defer g.deinit();
    try g.addWeightedEdge(5, 3, 1.0);
    try std.testing.expect(g.hasNode(5));
    try std.testing.expect(g.hasNode(3));
    try std.testing.expect(!g.hasNode(8));
    try std.testing.expect(g.hasEdge(5, 3));
    try std.testing.expect(g.hasEdge(3, 5));
    try std.testing.expect(!g.hasEdge(8, 5));
    const weight = try g.getWeight(5, 3);
    if (weight) |w| {
        try std.testing.expect(w == 1.0);
        try std.testing.expect(w != 5.0);
    }
}

test "GraphBasicMetrics" {
    var g = try Graph(u8).init(std.testing.allocator, GraphType.Undirected);
    defer g.deinit();
    try std.testing.expect(g.numberOfNodes() == 0);
    try g.addEdge(5, 3);
    const edges = try g.getEdges(std.testing.allocator);
    defer std.testing.allocator.free(edges);
    try std.testing.expect(g.hasEdge(edges[0].node_a, edges[0].node_b));
    try std.testing.expect(g.numberOfNodes() == 2);
    try std.testing.expect(g.numberOfEdges() == 1);
}

test "GraphPredSuc" {
    var g = try Graph(u8).init(std.testing.allocator, GraphType.Directed);
    defer g.deinit();
    try g.addEdge(1, 2);
    try g.addEdge(2, 3);
    try g.addEdge(1, 3);
    try g.addEdge(2, 4);
    try g.addEdge(4, 1);
    // inDegree and outDegree
    try std.testing.expect(try g.inDegree(3) == 2);
    try std.testing.expect(try g.outDegree(2) == 2);
    // Predecessors and successors
    const pred = try g.getPredecessors(std.testing.allocator, 4);
    defer std.testing.allocator.free(pred);
    try std.testing.expect(std.mem.eql(u8, &[_]u8{2}, pred));
    const succ = try g.getSuccesors(std.testing.allocator, 1);
    defer std.testing.allocator.free(succ);
    try std.testing.expect(std.mem.eql(u8, &[_]u8{2, 3}, succ));
}

test "GraphWithEnums" {
    const allocator = std.testing.allocator;
    const City = enum {
        NEW_YORK,
        LOS_ANGELES,
        CHICAGO,
        HOUSTON,
    };
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
