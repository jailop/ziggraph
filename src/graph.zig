//! A basic Graph type to use with Zig's primitive types

const std = @import("std");

/// A graph can be of type directed or undirected
pub const GraphType = enum {
    Directed,
    Undirected,
};

pub const GraphError = error{
    NodeAlreadyExists,
    NodeNotExists,
    EdgeAlreadyExists,
    EdgeNotExists,
    PathNotExists,
};

pub fn Graph(comptime T: type) type {
    return struct {
        const Node = struct {
            adjs: std.ArrayList(T),
            weights: std.ArrayList(?f64),
        };

        pub const Edge = struct {
            a: T,
            b: T,
        };

        const Self = @This();
        nodes: std.ArrayList(T),
        root: std.ArrayList(Node),
        allocator: std.mem.Allocator,
        gType: GraphType,

        pub fn init(comptime allocator: std.mem.Allocator, comptime gType: GraphType) !Self {
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

        pub fn hasEdge(self: *Self, vertex_a: T, vertex_b: T) bool {
            const node = self.getNode(vertex_a);
            if (node) |n| {
                for (n.adjs.items) |vertex| {
                    if (vertex == vertex_b) {
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

        fn _addEdge(self: *Self, vertex_a: T, vertex_b: T, weight: ?f64) !void {
            if (!self.hasNode(vertex_b)) {
                try self.addNode(vertex_b);
            }
            if (!self.hasNode(vertex_a)) {
                try self.addNode(vertex_a);
            }
            const node = self.getNode(vertex_a);
            if (node) |n| {
                for (n.adjs.items) |vertex| {
                    if (vertex == vertex_b) {
                        return GraphError.EdgeAlreadyExists;
                    }
                }
                try n.adjs.append(vertex_b);
                try n.weights.append(weight);
            }
        }

        pub fn addWeightedEdge(self: *Self, vertex_a: T, vertex_b: T, weight: ?f64) !void {
            try self._addEdge(vertex_a, vertex_b, weight);
            if (self.gType == GraphType.Undirected) {
                try self._addEdge(vertex_b, vertex_a, weight);
            }
        }

        pub fn addEdge(self: *Self, vertex_a: T, vertex_b: T) !void {
            try self.addWeightedEdge(vertex_a, vertex_b, undefined);
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

        pub fn getWeight(self: *Self, vertex_a: T, vertex_b: T) !?f64 {
            const node = self.getNode(vertex_a);
            if (node) |n| {
                for (0..n.adjs.items.len) |i| {
                    if (n.adjs.items[i] == vertex_b) {
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

        /// Returns a list of vertex that are predecessor of the required one.
        /// If the required vertex doesn't exist, an error is returned.
        /// If the required vertex doesn't have any predecessor, a empty list
        /// is returned.
        pub fn getPredecessors(self: *Self, allocator: std.mem.Allocator, vertex: T) ![]T {
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
        
        /// Returns the list of edges defined in the graph.
        pub fn getEdges(self: *Self, allocator: std.mem.Allocator) ![]Self.Edge {
            var edges = std.ArrayList(Self.Edge).init(self.allocator);
            defer edges.deinit();
            for (0..self.root.items.len) |i| {
                for (self.root.items[i].adjs.items) |vertex| {
                    try edges.append(Self.Edge{
                        .a = self.nodes.items[i],
                        .b = vertex,
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
    const pred = try g.getPredecessors(std.testing.allocator, 4);
    defer std.testing.allocator.free(pred);
    try std.testing.expect(std.mem.eql(u8, &[_]u8{2}, pred));
    const succ = try g.getSuccesors(std.testing.allocator, 1);
    defer std.testing.allocator.free(succ);
    try std.testing.expect(std.mem.eql(u8, &[_]u8{2, 3}, succ));
    const edges = try g.getEdges(std.testing.allocator);
    defer std.testing.allocator.free(edges);
    try std.testing.expect(g.hasEdge(edges[0].a, edges[0].b));
}
