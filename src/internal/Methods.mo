import Prim "mo:prim";

import Option "mo:base/Option";
import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Order "mo:base/Order";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Result "mo:base/Result";
import Buffer "mo:base/Buffer";
import BufferDeque "mo:buffer-deque/BufferDeque";

import ArrayMut "../internal/ArrayMut";
import Itertools "mo:itertools/Iter";
import Utils "../internal/Utils";
import T "Types";
import Cursor "Cursor";
import InternalTypes "../internal/Types";
import DoubleEndedIter "../internal/DoubleEndedIter";

module InternalMethods {
    type Iter<A> = Iter.Iter<A>;
    type Order = Order.Order;
    type CmpFn<A> = (A, A) -> Order;
    type Result<A, B> = Result.Result<A, B>;
    type BufferDeque<A> = BufferDeque.BufferDeque<A>;
    public type Cursor<K, V, Extra> = Cursor.Cursor<K, V>;
    public type DoubleEndedIter<A> = DoubleEndedIter.DoubleEndedIter<A>;

    public type BpTree<K, V, Extra> = InternalTypes.BpTree<K, V, Extra>;
    public type Node<K, V, Extra> = InternalTypes.Node<K, V, Extra>;
    public type Leaf<K, V, Extra> = InternalTypes.Leaf<K, V, Extra>;
    public type Branch<K, V, Extra> = InternalTypes.Branch<K, V, Extra>;
    type CommonFields<K, V, Extra> = InternalTypes.CommonFields<K, V, Extra>;
    type CommonNodeFields<K, V, Extra> = InternalTypes.CommonNodeFields<K, V, Extra>;
    type MultiCmpFn<A, B> = (A, B) -> Order;

    public func depth<K, V, Extra>(bptree : BpTree<K, V, Extra>) : Nat {
        var node = ?bptree.root;
        var depth = 0;

        label while_loop loop {
            switch (node) {
                case (? #branch(n)) {
                    node := n.children[0];
                    depth += 1;
                };
                case (? #leaf(_)) {
                    return depth + 1;
                };
                case (_) Debug.trap("depth: accessed a null value");
            };
        };

        depth;
    };

    public func get_leaf_node<K, V, Extra>(self : BpTree<K, V, Extra>, cmp : CmpFn<K>, key : K) : Leaf<K, V, Extra> {
        var curr = ?self.root;

        loop {
            switch (curr) {
                case (? #branch(node)) {
                    let int_index = ArrayMut.binary_search<K, K>(node.keys, cmp, key, node.count - 1);
                    let node_index = if (int_index >= 0) Int.abs(int_index) + 1 else Int.abs(int_index + 1);
                    curr := node.children[node_index];
                };
                case (? #leaf(leaf_node)) {
                    return leaf_node;
                };
                case (_) Debug.trap("get_leaf_node: accessed a null value");
            };
        };
    };

    public func update_branch_path_from_leaf_to_root<K, V, Extra>(self : BpTree<K, V, Extra>, leaf : Leaf<K, V, Extra>, update : (Branch<K, V, Extra>) -> ()) {
        var parent = leaf.parent;

        loop {
            switch (parent) {
                case (?node) {
                    update(node);
                    parent := node.parent;
                };

                case (_) return;
            };
        };
    };

    public func get_leaf_node_and_update_branch_path<K, V, Extra>(self : BpTree<K, V, Extra>, cmp : CmpFn<K>, key : K, update : (Branch<K, V, Extra>) -> ()) : Leaf<K, V, Extra> {
        var curr = ?self.root;

        loop {
            switch (curr) {
                case (? #branch(node)) {
                    let int_index = ArrayMut.binary_search<K, K>(node.keys, cmp, key, node.count - 1);
                    let node_index = if (int_index >= 0) Int.abs(int_index) + 1 else Int.abs(int_index + 1);
                    update(node);

                    curr := node.children[node_index];
                };
                case (? #leaf(leaf_node)) {
                    return leaf_node;
                };
                case (_) Debug.trap("get_leaf_node: accessed a null value");
            };
        };
    };

    public func get_min_leaf_node<K, V, Extra>(self : BpTree<K, V, Extra>) : Leaf<K, V, Extra> {
        var node = ?self.root;

        loop {
            switch (node) {
                case (? #branch(branch)) {
                    node := branch.children[0];
                };
                case (? #leaf(leaf_node)) {
                    return leaf_node;
                };
                case (_) Debug.trap("get_min_leaf_node: accessed a null value");
            };
        };
    };

    public func get_max_leaf_node<K, V, Extra>(self : BpTree<K, V, Extra>) : Leaf<K, V, Extra> {
        var node = ?self.root;

        loop {
            switch (node) {
                case (? #branch(branch)) {
                    node := branch.children[branch.count - 1];
                };
                case (? #leaf(leaf_node)) {
                    return leaf_node;
                };
                case (_) Debug.trap("get_max_leaf_node: accessed a null value");
            };
        };
    };

    public func cmp_key<K, V, Extra>(cmp : CmpFn<K>) : CmpFn<(K, V)> {
        func(a : (K, V), b : (K, V)) : Order {
            cmp(a.0, b.0);
        };
    };

    public func extract<T>(arr : [var ?T], index : Nat) : ?T {
        let tmp = arr[index];
        arr[index] := null;
        tmp;
    };

    public func gen_id<K, V, Extra>(bptree : BpTree<K, V, Extra>) : Nat {
        let id = bptree.next_id;
        bptree.next_id += 1;
        id;
    };

    public func inc_branch_subtree_size<K, V, Extra>(branch : Branch<K, V, Extra>) {
        branch.subtree_size += 1;
    };

    public func decrement_branch_subtree_size<K, V, Extra>(branch : Branch<K, V, Extra>) {
        branch.subtree_size -= 1;
    };

    public func subtree_size<K, V, Extra>(node : Node<K, V, Extra>) : Nat {
        switch (node) {
            case (#branch(node)) node.subtree_size;
            case (#leaf(node)) node.count;
        };
    };

    public func new_iterator<K, V, Extra>(
        start_leaf : Leaf<K, V, Extra>,
        start_index : Nat,
        end_leaf : Leaf<K, V, Extra>,
        end_index : Nat // exclusive
    ) : DoubleEndedIter<(K, V)> {

        var _start_leaf = ?start_leaf;
        var i = start_index;

        var _end_leaf = ?end_leaf;
        var j = end_index;

        func next() : ?(K, V) {
            let ?start = _start_leaf else return null;
            let ?end = _end_leaf else return null;

            if (start.id == end.id and i >= j) {
                _start_leaf := null;
                return null;
            };

            if (i >= start.count) {
                _start_leaf := start.next;
                i := 0;
                return next();
            };

            let entry = start.kvs[i];
            i += 1;
            return entry;
        };

        func nextFromEnd() : ?(K, V) {
            let ?start = _start_leaf else return null;
            let ?end = _end_leaf else return null;

            if (start.id == end.id and i >= j) {
                _end_leaf := null;
                return null;
            };

            if (j == 0) {
                _end_leaf := end.prev;
                switch (_end_leaf) {
                    case (?leaf) j := leaf.count;
                    case (_) { return null };
                };

                return nextFromEnd();
            };

            let entry = end.kvs[j - 1];
            j -= 1;
            return entry;
        };

        DoubleEndedIter.new(next, nextFromEnd);
    };

    // Returns the leaf node and rank of the first element in the leaf node
    public func get_leaf_node_and_rank<K, V, Extra>(self : BpTree<K, V, Extra>, cmp : CmpFn<K>, key : K) : (Leaf<K, V, Extra>, Nat) {

        let root = switch (self.root) {
            case (#branch(node)) node;
            case (#leaf(node)) return (node, node.count);
        };

        var rank = root.subtree_size;

        func get_node(parent : Branch<K, V, Extra>, key : K) : Leaf<K, V, Extra> {
            var i = parent.count - 1 : Nat;

            label get_node_loop while (i >= 1) {
                let child = parent.children[i];

                let ?search_key = parent.keys[i - 1] else Debug.trap("get_leaf_node_and_rank 1: accessed a null value");

                switch (child) {
                    case (? #branch(node)) {
                        if (cmp(key, search_key) == #greater) {
                            return get_node(node, key);
                        };

                        rank -= node.subtree_size;
                    };
                    case (? #leaf(node)) {
                        // subtract before comparison because we want the rank of the first element in the leaf node
                        rank -= node.count;

                        if (cmp(key, search_key) == #greater) {
                            return node;
                        };
                    };
                    case (_) Debug.trap("get_leaf_node_and_rank 2: accessed a null value");
                };

                i -= 1;
            };

            switch (parent.children[0]) {
                case (? #branch(node)) {
                    return get_node(node, key);
                };
                case (? #leaf(node)) {
                    rank -= node.count;
                    return node;
                };
                case (_) Debug.trap("get_leaf_node_and_rank 3: accessed a null value");
            };
        };

        (get_node(root, key), rank);
    };

    public func get_leaf_node_by_rank<K, V, Extra>(self : BpTree<K, V, Extra>, rank : Nat) : (Leaf<K, V, Extra>, Nat) {
        let root = switch (self.root) {
            case (#branch(node)) node;
            case (#leaf(leaf)) return (leaf, rank);
        };

        var search_rank = rank;

        func get_node(parent : Branch<K, V, Extra>) : Leaf<K, V, Extra> {
            var i = parent.count - 1 : Nat;
            var curr = ?parent;
            var node_rank = parent.subtree_size;

            label get_node_loop loop {
                let child = parent.children[i];

                switch (child) {
                    case (? #branch(node)) {
                        let subtree = node.subtree_size;

                        node_rank -= subtree;
                        if (node_rank <= search_rank) {
                            search_rank -= node_rank;
                            return get_node(node);
                        };

                    };
                    case (? #leaf(node)) {
                        let subtree = node.count;
                        node_rank -= subtree;

                        if (node_rank <= search_rank) {
                            search_rank -= node_rank;
                            return node;
                        };

                    };
                    case (_) Debug.trap("get_leaf_node_by_rank 1: accessed a null value");
                };

                assert i > 0;

                i -= 1;
            };

            Debug.trap("get_leaf_node_by_rank 3: reached unreachable code");
        };

        (get_node(root), search_rank);
    };

    // // merges two leaf nodes into the left node
    // public func merge_leaf_nodes<K, V, Extra>(left : Leaf<K, V, Extra>, right : Leaf<K, V, Extra>) {
    //     let min_count = left.kvs.size() / 2;

    //     var i = 0;

    //     // merge right into left
    //     for (_ in Iter.range(0, right.count - 1)) {
    //         let val = right.kvs[i];
    //         ArrayMut.insert(left.kvs, left.count + i, val, left.count);

    //         i += 1;
    //     };

    //     left.count += right.count;

    //     // update leaf pointers
    //     left.next := right.next;
    //     switch (left.next) {
    //         case (?next) next.prev := ?left;
    //         case (_) {};
    //     };

    //     // update parent keys
    //     switch (left.parent) {
    //         case (null) {};
    //         case (?parent) {
    //             ignore ArrayMut.remove(parent.keys, right.index - 1 : Nat, parent.count - 1 : Nat);
    //             ignore Branch.remove(parent, right.index : Nat, parent.count);

    //             parent.count -= 1;
    //         };
    //     };

    // };


    public func get<K, V, Extra>(self : BpTree<K, V, Extra>, cmp : CmpFn<K>, key : K) : ?V {
        let leaf_node = InternalMethods.get_leaf_node<K, V, Extra>(self, cmp, key);

        let i = ArrayMut.binary_search<K, (K, V)>(leaf_node.kvs, Utils.adapt_cmp(cmp), key, leaf_node.count);

        if (i >= 0) {
            let ?kv = leaf_node.kvs[Int.abs(i)] else Debug.trap("1. get: accessed a null value");
            return ?kv.1;
        };

        null;
    };

    public func to_array<K, V, Extra>(self : BpTree<K, V, Extra>) : [(K, V)] {
        var node = ?self.root;
        let buffer = Buffer.Buffer<(K, V)>(self.size);

        var leaf_node : ?Leaf<K, V, Extra> = ?InternalMethods.get_min_leaf_node(self);

        label _loop loop {
            switch (leaf_node) {
                case (?leaf) {
                    label _for_loop for (opt in leaf.kvs.vals()) {
                        let ?kv = opt else break _for_loop;
                        buffer.add(kv);
                    };

                    leaf_node := leaf.next;
                };
                case (_) break _loop;
            };
        };

        Buffer.toArray(buffer);
    };

     public func min<K, V, Extra>(self : BpTree<K, V, Extra>) : ?(K, V) {
        let leaf_node = InternalMethods.get_min_leaf_node(self) else return null;
        leaf_node.kvs[0];
    };

    // Returns the maximum key-value pair in the tree.
    public func max<K, V, Extra>(self : BpTree<K, V, Extra>) : ?(K, V) {
        let leaf_node = InternalMethods.get_max_leaf_node(self) else return null;
        leaf_node.kvs[leaf_node.count - 1];
    };

    // Returns a double ended iterator over the entries of the tree.
    public func entries<K, V, Extra>(bptree : BpTree<K, V, Extra>) : DoubleEndedIter<(K, V)> {
        let min_leaf = InternalMethods.get_min_leaf_node(bptree);
        let max_leaf = InternalMethods.get_max_leaf_node(bptree);
        InternalMethods.new_iterator(min_leaf, 0, max_leaf, max_leaf.count);
    };

    // Returns a double ended iterator over the keys of the tree.
    public func keys<K, V, Extra>(self : BpTree<K, V, Extra>) : DoubleEndedIter<K> {
        DoubleEndedIter.map(
            entries(self),
            func(kv : (K, V)) : K {
                kv.0;
            },
        );
    };

    // Returns a double ended iterator over the values of the tree.
    public func vals<K, V, Extra>(self : BpTree<K, V, Extra>) : DoubleEndedIter<V> {
        DoubleEndedIter.map(
            entries(self),
            func(kv : (K, V)) : V {
                kv.1;
            },
        );
    };

    // Returns the rank of the given key in the tree.
    public func get_rank<K, V, Extra>(self : BpTree<K, V, Extra>, cmp : CmpFn<K>, key : K) : Nat {
        let (leaf_node, rank) = InternalMethods.get_leaf_node_and_rank(self, cmp, key);
        let i = ArrayMut.binary_search<K, (K, V)>(leaf_node.kvs, Utils.adapt_cmp(cmp), key, leaf_node.count);

        if (i < 0) {
            return rank + (Int.abs(i) - 1 : Nat);
        };

        rank + Int.abs(i);
    };

    // Returns the key-value pair at the given rank.
    // Returns null if the rank is greater than the size of the tree.
    public func get_by_rank<K, V, Extra>(self : BpTree<K, V, Extra>, rank : Nat) : (K, V) {
        if (rank >= self.size) return Debug.trap("getByRank: rank is greater than the size of the tree");
        let (leaf_node, i) = InternalMethods.get_leaf_node_by_rank(self, rank);

        assert i < leaf_node.count;

        let ?entry = leaf_node.kvs[i] else Debug.trap("getByRank: accessed a null value");
        entry;
    };

    // Returns an iterator over the entries of the tree in the range [start, end].
    // The range is defined by the ranks of the start and end keys
    public func range<K, V, Extra>(self : BpTree<K, V, Extra>, start : Nat, end : Nat) : DoubleEndedIter<(K, V)> {
        let (start_node, start_node_rank) = InternalMethods.get_leaf_node_by_rank(self, start);
        let (end_node, end_node_rank) = InternalMethods.get_leaf_node_by_rank(self, end);

        let start_index = start_node_rank : Nat;
        let end_index = end_node_rank + 1 : Nat; // + 1 because the end index is exclusive

        InternalMethods.new_iterator(start_node, start_index, end_node, end_index);
    };

    // Returns an iterator over the entries of the tree in the range [start, end].
    // The iterator is inclusive of start and end.
    //
    // If the start key does not exist in the tree then the iterator will start from next key greater than start.
    // If the end key does not exist in the tree then the iterator will end at the last key less than end.
    public func scan<K, V, Extra>(self : BpTree<K, V, Extra>, cmp : CmpFn<K>, start : K, end : K) : DoubleEndedIter<(K, V)> {
        let left_node = InternalMethods.get_leaf_node(self, cmp, start);
        let start_index = ArrayMut.binary_search<K, (K, V)>(left_node.kvs, Utils.adapt_cmp(cmp), start, left_node.count);

        // if start_index is negative then the element was not found
        // moreover if start_index is negative then abs(i) - 1 is the index of the first element greater than start
        var i = if (start_index >= 0) Int.abs(start_index) else Int.abs(start_index) - 1 : Nat;

        let right_node = InternalMethods.get_leaf_node(self, cmp, end);
        let end_index = ArrayMut.binary_search<K, (K, V)>(right_node.kvs, Utils.adapt_cmp(cmp), end, right_node.count);
        var j = if (end_index >= 0) Int.abs(end_index) + 1 else Int.abs(end_index) - 1 : Nat;

        InternalMethods.new_iterator(left_node, i, right_node, j);
    };

};
