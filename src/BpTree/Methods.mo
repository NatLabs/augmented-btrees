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

import LeafModule "Leaf";
import BranchModule "Branch";

import ArrayMut "../internal/ArrayMut";
import Itertools "mo:itertools/Iter";
import Utils "../internal/Utils";
import T "Types";
import Cursor "Cursor";
import InternalTypes "../internal/Types";
import DoubleEndedIter "../internal/DoubleEndedIter";

module Methods {
    type Iter<A> = Iter.Iter<A>;
    type Order = Order.Order;
    type CmpFn<A> = (A, A) -> Order;
    type Result<A, B> = Result.Result<A, B>;
    type BufferDeque<A> = BufferDeque.BufferDeque<A>;
    public type Cursor<K, V, Extra> = Cursor.Cursor<K, V>;
    public type DoubleEndedIter<A> = DoubleEndedIter.DoubleEndedIter<A>;

    public let Leaf = LeafModule;
    public let Branch = BranchModule;

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

    public func unique_id<K, V, Extra>(bptree : BpTree<K, V, Extra>) : Nat {
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
        let leaf_node = Methods.get_leaf_node<K, V, Extra>(self, cmp, key);

        let i = ArrayMut.binary_search<K, (K, V)>(leaf_node.kvs, Utils.adapt_cmp(cmp), key, leaf_node.count);

        if (i >= 0) {
            let ?kv = leaf_node.kvs[Int.abs(i)] else Debug.trap("1. get: accessed a null value");
            return ?kv.1;
        };

        null;
    };

    public func insert<K, V, Extra>(
        self : BpTree<K, V, Extra>, 
        cmp : CmpFn<K>, 
        key : K, 
        val : V, 
        leaf_split: (Leaf<K, V, Extra>, Nat, (K, V), () -> Nat) -> Leaf<K, V, Extra>,
        branch_new: (Nat, ?[var ?Node<K, V, Extra>], () -> Nat) -> Branch<K, V, Extra>,
        branch_split: (Branch<K, V, Extra>, Node<K, V, Extra>, Nat, K, () -> Nat) -> Branch<K, V, Extra>,
    ) : ?V {
        func inc_branch_subtree_size(branch : Branch<K, V, Extra>) {
            branch.subtree_size += 1;
        };

        func decrement_branch_subtree_size(branch : Branch<K, V, Extra>) {
            branch.subtree_size -= 1;
        };

        func adapt_cmp<K, V, Extra>(cmp : T.CmpFn<K>) : InternalTypes.MultiCmpFn<K, (K, V)> {
            func(a : K, b : (K, V)) : Order {
                cmp(a, b.0);
            };
        };

        func gen_id() : Nat = Methods.unique_id<K, V, Extra>(self);

        let leaf_node = Methods.get_leaf_node_and_update_branch_path<K, V, Extra>(self, cmp, key, inc_branch_subtree_size);
        let entry = (key, val);

        let int_elem_index = ArrayMut.binary_search<K, (K, V)>(leaf_node.kvs, adapt_cmp(cmp), key, leaf_node.count);
        let elem_index = if (int_elem_index >= 0) Int.abs(int_elem_index) else Int.abs(int_elem_index + 1);

        let prev_value = if (int_elem_index >= 0) {
            let ?kv = leaf_node.kvs[elem_index] else Debug.trap("1. insert: accessed a null value while replacing a key-value pair");
            leaf_node.kvs[elem_index] := ?entry;

            // undoes the update to subtree count for the nodes on the path to the root when replacing a key-value pair
            Methods.update_branch_path_from_leaf_to_root<K, V, Extra>(self, leaf_node, decrement_branch_subtree_size);

            return ?kv.1;
        } else {
            null;
        };

        if (leaf_node.count < self.order) {
            // shift elems to the right and insert the new key-value pair
            var j = leaf_node.count;

            while (j > elem_index) {
                leaf_node.kvs[j] := leaf_node.kvs[j - 1];
                j -= 1;
            };

            leaf_node.kvs[elem_index] := ?entry;
            leaf_node.count += 1;

            self.size += 1;
            return prev_value;
        };

        // split leaf node
        let right_leaf_node = leaf_split(leaf_node, elem_index, entry, gen_id);

        var opt_parent : ?Branch<K, V, Extra> = leaf_node.parent;
        var left_node : Node<K, V, Extra> = #leaf(leaf_node);
        var left_index = leaf_node.index;

        var right_index = right_leaf_node.index;
        let ?right_leaf_first_entry = right_leaf_node.kvs[0] else Debug.trap("2. insert: accessed a null value");
        var right_key = right_leaf_first_entry.0;
        var right_node : Node<K, V, Extra> = #leaf(right_leaf_node);

        // insert split leaf nodes into parent nodes if there is space
        // or iteratively split parent (internal) nodes to make space
        label index_split_loop while (Option.isSome(opt_parent)) {
            var subtree_diff : Nat = 0;
            let ?parent = opt_parent else Debug.trap("3. insert: accessed a null parent value");

            parent.subtree_size -= subtree_diff;

            if (parent.count < self.order) {
                var j = parent.count;

                while (j >= right_index) {
                    if (j == right_index) {
                        parent.keys[j - 1] := ?right_key;
                        parent.children[j] := ?right_node;
                    } else {
                        parent.keys[j - 1] := parent.keys[j - 2];
                        parent.children[j] := parent.children[j - 1];
                    };

                    switch (parent.children[j]) {
                        case ((? #branch(node) or ? #leaf(node)) : ?CommonNodeFields<K, V, Extra>) {
                            node.index := j;
                        };
                        case (_) {};
                    };

                    j -= 1;
                };

                parent.count += 1;

                self.size += 1;
                return prev_value;

            } else {

                let median = (parent.count / 2) + 1; // include inserted key-value pair
                let prev_subtree_size = parent.subtree_size;

                let split_node = branch_split(parent, right_node, right_index, right_key, gen_id);

                let ?first_key = Methods.extract(split_node.keys, split_node.keys.size() - 1 : Nat) else Debug.trap("4. insert: accessed a null value in first key of branch");
                right_key := first_key;

                left_node := #branch(parent);
                right_node := #branch(split_node);

                right_index := split_node.index;
                opt_parent := split_node.parent;

                subtree_diff := prev_subtree_size - parent.subtree_size;
            };
        };

        let children = Array.init<?Node<K, V, Extra>>(self.order, null);
        children[0] := ?left_node;
        children[1] := ?right_node;

        let root_node = branch_new(self.order, ?children, gen_id);
        root_node.keys[0] := ?right_key;

        self.root := #branch(root_node);
        self.size += 1;

        prev_value;
    };
};
