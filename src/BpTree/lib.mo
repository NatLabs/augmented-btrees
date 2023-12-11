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

module BpTree {
    type Iter<A> = Iter.Iter<A>;
    type Order = Order.Order;
    type CmpFn<A> = (A, A) -> Order;
    type Result<A, B> = Result.Result<A, B>;
    type BufferDeque<A> = BufferDeque.BufferDeque<A>;
    public type Cursor<K, V> = Cursor.Cursor<K, V>;
    public type DoubleEndedIter<A> = DoubleEndedIter.DoubleEndedIter<A>;

    public let Leaf = LeafModule;
    public let Branch = BranchModule;

    public type BpTree<K, V> = T.BpTree<K, V>;
    public type Node<K, V> = T.Node<K, V>;
    public type Leaf<K, V> = T.Leaf<K, V>;
    public type Branch<K, V> = T.Branch<K, V>;
    type SharedNodeFields<K, V> = T.SharedNodeFields<K, V>;
    type SharedNode<K, V> = T.SharedNode<K, V>;
    type MultiCmpFn<A, B> = (A, B) -> Order;

    // public func new2<K, V>(): T.BpTreeV2<K, V> {
    //     new<K, V>();
    // };

    public func new<K, V>(_order : ?Nat) : BpTree<K, V> {
        let order = Option.get(_order, 32);

        assert order >= 4 and order <= 512;

        {
            order;
            var root = #leaf(Leaf.new<K, V>(order, 0, null, func() : Nat = 0));
            var size = 0;
            var next_id = 1;
        };
    };

    public func size<K, V>(self : BpTree<K, V>) : Nat {
        self.size;
    };

    public func depth<K, V>(bptree : BpTree<K, V>) : Nat {
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

    public func get_leaf_node<K, V>(self : BpTree<K, V>, cmp : CmpFn<K>, key : K) : Leaf<K, V> {
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

    public func update_branch_path_from_leaf_to_root<K, V>(self : BpTree<K, V>, leaf : Leaf<K, V>, update : (Branch<K, V>) -> ()) {
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

    public func get_leaf_node_and_update_branch_path<K, V>(self : BpTree<K, V>, cmp : CmpFn<K>, key : K, update : (Branch<K, V>) -> ()) : Leaf<K, V> {
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

    public func get_min_leaf_node<K, V>(self : BpTree<K, V>) : Leaf<K, V> {
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

    public func get_max_leaf_node<K, V>(self : BpTree<K, V>) : Leaf<K, V> {
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

    public func get<K, V>(self : BpTree<K, V>, cmp : CmpFn<K>, key : K) : ?V {
        let leaf_node = get_leaf_node<K, V>(self, cmp, key);

        let i = ArrayMut.binary_search<(K, V), K>(leaf_node.kvs, Utils.adapt_cmp(cmp), key, leaf_node.count);

        if (i >= 0) {
            let ?kv = leaf_node.kvs[Int.abs(i)] else Debug.trap("1. get: accessed a null value");
            return ?kv.1;
        };

        null;
    };

    func cmp_key<K, V>(cmp : CmpFn<K>) : CmpFn<(K, V)> {
        func(a : (K, V), b : (K, V)) : Order {
            cmp(a.0, b.0);
        };
    };

    func extract<T>(arr : [var ?T], index : Nat) : ?T {
        let tmp = arr[index];
        arr[index] := null;
        tmp;
    };

    public func toText<K, V>(self : BpTree<K, V>, key_to_text : (K) -> Text, val_to_text : (V) -> Text) : Text {
        var t = "BpTree { order: " # debug_show self.order # ", size: " # debug_show self.size # ", root: ";

        t #= switch (self.root) {
            case (#leaf(node)) "leaf { " # Leaf.toText<K, V>(node, key_to_text, val_to_text) # " }";
            case (#branch(node)) "branch {" # Branch.toText<K, V>(node, key_to_text, val_to_text) # "}";
        };

        t #= "}";

        t;
    };

    public func indexes<K, V>(children : [var ?Node<K, V>]) : [Int] {
        Array.map<?Node<K, V>, Int>(
            Array.freeze(children),
            func(opt_node : ?Node<K, V>) : Int {
                switch (opt_node) {
                    case ((? #branch(node) or ? #leaf(node)) : ?SharedNode<K, V>) node.index;
                    case (_) -1;
                };
            },
        );
    };

    public func unique_id<K, V>(bptree : BpTree<K, V>) : Nat {
        let id = bptree.next_id;
        bptree.next_id += 1;
        id;
    };

    func inc_branch_subtree_size(branch : Branch<Nat, Nat>) {
        branch.subtree_size += 1;
    };

    func decrement_branch_subtree_size(branch : Branch<Nat, Nat>) {
        branch.subtree_size -= 1;
    };

    public func insert(self : BpTree<Nat, Nat>, cmp : CmpFn<Nat>, key : Nat, val : Nat) : ?Nat {

        func gen_id() : Nat = unique_id(self);

        let leaf_node = get_leaf_node_and_update_branch_path<Nat, Nat>(self, cmp, key, inc_branch_subtree_size);
        let entry = (key, val);

        let int_elem_index = ArrayMut.binary_search<(Nat, Nat), Nat>(leaf_node.kvs, Utils.adapt_cmp(cmp), key, leaf_node.count);
        let elem_index = if (int_elem_index >= 0) Int.abs(int_elem_index) else Int.abs(int_elem_index + 1);

        let prev_value = if (int_elem_index >= 0) {
            let ?kv = leaf_node.kvs[elem_index] else Debug.trap("1. insert: accessed a null value while replacing a key-value pair");
            leaf_node.kvs[elem_index] := ?entry;

            // undoes the update to subtree count for the nodes on the path to the root when replacing a key-value pair
            update_branch_path_from_leaf_to_root(self, leaf_node, decrement_branch_subtree_size);

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
        let right_leaf_node = Leaf.split(leaf_node, elem_index, entry, gen_id);

        var opt_parent : ?Branch<Nat, Nat> = leaf_node.parent;
        var left_node : Node<Nat, Nat> = #leaf(leaf_node);
        var left_index = leaf_node.index;

        var right_index = right_leaf_node.index;
        let ?right_leaf_first_entry = right_leaf_node.kvs[0] else Debug.trap("2. insert: accessed a null value");
        var right_key = right_leaf_first_entry.0;
        var right_node : Node<Nat, Nat> = #leaf(right_leaf_node);

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
                        case ((? #branch(node) or ? #leaf(node)) : ?SharedNode<Nat, Nat>) {
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

                let split_node = Branch.split(parent, right_node, right_index, right_key, gen_id);

                let ?first_key = extract(split_node.keys, split_node.keys.size() - 1 : Nat) else Debug.trap("4. insert: accessed a null value in first key of branch");
                right_key := first_key;

                left_node := #branch(parent);
                right_node := #branch(split_node);

                right_index := split_node.index;
                opt_parent := split_node.parent;

                subtree_diff := prev_subtree_size - parent.subtree_size;
            };
        };

        let children = Array.init<?Node<Nat, Nat>>(self.order, null);
        children[0] := ?left_node;
        children[1] := ?right_node;

        let root_node = Branch.new<Nat, Nat>(self.order, ?children, gen_id);
        root_node.keys[0] := ?right_key;

        self.root := #branch(root_node);
        self.size += 1;
     
        prev_value;
    };

    public func subtrees<K, V>(node : Branch<K, V>) : [Nat] {
        Array.tabulate(
            node.count,
            func(i : Nat) : Nat {
                let ?child = node.children[i] else Debug.trap("subtrees: accessed a null value");
                switch (child) {
                    case (#branch(node)) node.subtree_size;
                    case (#leaf(node)) node.count;
                };
            },
        );
    };

    public func subtree_size<K, V>(node : Node<K, V>) : Nat {
        switch (node) {
            case (#branch(node)) node.subtree_size;
            case (#leaf(node)) node.count;
        };
    };

    // merges two leaf nodes into the left node
    public func merge_leaf_nodes(left : Leaf<Nat, Nat>, right : Leaf<Nat, Nat>) {
        let min_count = left.kvs.size() / 2;

        var i = 0;

        // merge right into left
        for (_ in Iter.range(0, right.count - 1)) {
            let val = right.kvs[i];
            ArrayMut.insert(left.kvs, left.count + i, val, left.count);

            i += 1;
        };

        left.count += right.count;

        // update leaf pointers
        left.next := right.next;
        switch (left.next) {
            case (?next) next.prev := ?left;
            case (_) {};
        };

        // update parent keys
        switch (left.parent) {
            case (null) {};
            case (?parent) {
                ignore ArrayMut.remove(parent.keys, right.index - 1 : Nat, parent.count - 1 : Nat);
                ignore Branch.remove(parent, right.index : Nat, parent.count);

                parent.count -= 1;
            };
        };

    };

    public func remove(self : BpTree<Nat, Nat>, cmp : CmpFn<Nat>, key : Nat) : ?Nat {
        let leaf_node = get_leaf_node_and_update_branch_path<Nat, Nat>(self, cmp, key, decrement_branch_subtree_size);

        let int_elem_index = ArrayMut.binary_search<(Nat, Nat), Nat>(leaf_node.kvs, Utils.adapt_cmp(cmp), key, leaf_node.count);
        let elem_index = if (int_elem_index >= 0) Int.abs(int_elem_index) else {
            update_branch_path_from_leaf_to_root(self, leaf_node, inc_branch_subtree_size);
            return null;
        };
        // remove parent key as well
        let ?entry : ?(Nat, Nat) = ArrayMut.remove(leaf_node.kvs, elem_index, leaf_node.count) else Debug.trap("1. remove: accessed a null value");

        let deleted = entry.1;
        self.size -= 1;
        leaf_node.count -= 1;

        let min_count = self.order / 2;

        let ?_parent = leaf_node.parent else return ?deleted; // if parent is null then leaf_node is the root
        var parent = _parent;

        func update_deleted_median_key(_parent : Branch<Nat, Nat>, index : Nat, deleted_key : Nat, next_key : Nat) {
            var parent = _parent;
            var i = index;

            while (i == 0) {
                i := parent.index;
                let ?__parent = parent.parent else return; // occurs when key is the first key in the tree
                parent := __parent;
            };

            assert parent.keys[i - 1] == ?deleted_key;
            parent.keys[i - 1] := ?next_key;
        };

        if (elem_index == 0) {
            let next = leaf_node.kvs[elem_index]; // same as entry index because we removed the entry from the array
            let ?next_key = do ? { next!.0 } else Debug.trap("update_deleted_median_key: accessed a null value");
            update_deleted_median_key(parent, leaf_node.index, key, next_key);
        };

        if (leaf_node.count >= min_count) return ?deleted;

        Leaf.redistribute_keys(leaf_node);

        if (leaf_node.count >= min_count) return ?deleted;

        // the parent will always have (self.order / 2) children
        let opt_adj_node = if (leaf_node.index == 0) {
            parent.children[1];
        } else {
            parent.children[leaf_node.index - 1];
        };

        let ? #leaf(adj_node) = opt_adj_node else return ?deleted;

        let left_node = if (adj_node.index < leaf_node.index) adj_node else leaf_node;
        let right_node = if (adj_node.index < leaf_node.index) leaf_node else adj_node;

        Leaf.merge(left_node, right_node);
        // remove merged right node from parent
        ignore ArrayMut.remove(parent.keys, right_node.index - 1 : Nat, parent.count - 1 : Nat);
        ignore Branch.remove(parent, right_node.index : Nat, parent.count);
        parent.count -= 1;

        // assert Utils.is_sorted<Nat>(parent.keys, Nat.compare);
        // assert validate_array_equal_count(parent.children, parent.count);

        var branch_node = parent;
        let ?__parent = branch_node.parent else {

            // update root node as this node does not have a parent
            // which means it is the root node
            if (branch_node.count == 1) {
                let ?child = branch_node.children[0] else Debug.trap("3. remove: accessed a null value");
                switch (child) {
                    case (#branch(node) or #leaf(node) : SharedNode<Nat, Nat>) {
                        node.parent := null;
                    };
                };
                self.root := child;

                // Debug.print("new root keys" # debug_show toNodeKeys(self));
                // Debug.print("new root leafs" # debug_show toLeafNodes(self));
            };

            return ?deleted;
        };

        parent := __parent;

        // Debug.print("branch_node count (" # debug_show branch_node.count # ") < min_count (" # debug_show min_count # ") ");

        while (branch_node.count < min_count) {
            Branch.redistribute_keys(branch_node);
            // assert Utils.is_sorted<Nat>(branch_node.keys, Nat.compare);

            if (branch_node.count >= min_count) return ?deleted;

            let ? #branch(adj_branch_node) = if (branch_node.index == 0) {
                parent.children[1];
            } else {
                parent.children[branch_node.index - 1];
            } else {
                // if the adjacent node is null then the branch node is the only child of the parent
                // this only happens if the branch node is the root node

                // update root node if necessary
                assert parent.count == 1;
                let ?child = parent.children[0] else Debug.trap("3. remove: accessed a null value");
                self.root := child;

                return ?deleted;
            };

            let left_node = if (adj_branch_node.index < branch_node.index) adj_branch_node else branch_node;
            let right_node = if (adj_branch_node.index < branch_node.index) branch_node else adj_branch_node;

            Branch.merge(left_node, right_node);

            // assert Utils.is_sorted<Nat>(left_node.keys, Nat.compare);

            branch_node := parent;
            let ?_parent = branch_node.parent else {
                // update root node if necessary
                if (branch_node.count == 1) {
                    let ?child = branch_node.children[0] else Debug.trap("3. remove: accessed a null value");
                    switch (child) {
                        case (#branch(node) or #leaf(node) : SharedNode<Nat, Nat>) {
                            node.parent := null;
                        };
                    };
                    self.root := child;
                };

                return ?deleted;
            };

            parent := _parent;
        };

        ?deleted;
    };

    public func min<K, V>(self : BpTree<K, V>) : ?(K, V) {
        let leaf_node = get_min_leaf_node(self) else return null;
        leaf_node.kvs[0];
    };

    public func max<K, V>(self : BpTree<K, V>) : ?(K, V) {
        let leaf_node = get_max_leaf_node(self) else return null;
        leaf_node.kvs[leaf_node.count - 1];
    };

    public func fromEntries(order : ?Nat, entries : Iter<(Nat, Nat)>, cmp : CmpFn<Nat>) : BpTree<Nat, Nat> {
        let bptree = BpTree.new<Nat, Nat>(order);

        for (entry in entries) {
            let (k, v) = entry;
            ignore insert(bptree, cmp, entry.0, entry.1);
        };

        bptree;
    };

    public func fromArray(order : ?Nat, arr : [(Nat, Nat)], cmp : CmpFn<Nat>) : BpTree<Nat, Nat> {
        let bptree = BpTree.new<Nat, Nat>(order);

        for (kv in arr.vals()) {
            let (k, v) = kv;
            ignore insert(bptree, cmp, k, v);
        };

        bptree;
    };

    public func toArray<K, V>(self : BpTree<K, V>) : [(K, V)] {
        var node = ?self.root;
        let buffer = Buffer.Buffer<(K, V)>(self.size);

        var leaf_node : ?Leaf<K, V> = ?get_min_leaf_node(self);

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

    func new_iterator<K, V>(
        start_leaf : Leaf<K, V>,
        start_index : Nat,
        end_leaf : Leaf<K, V>,
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
                    case (_) { return null; };
                };
                
                return nextFromEnd();
            };

            let entry = end.kvs[j - 1];
            j -= 1;
            return entry;
        };

        DoubleEndedIter.new(next, nextFromEnd);
    };

    public func entries<K, V>(bptree : BpTree<K, V>) : DoubleEndedIter<(K, V)> {
        let max_leaf = get_max_leaf_node(bptree);
        new_iterator<K, V>(get_min_leaf_node(bptree), 0, max_leaf, max_leaf.count);
    };

    public func keys<K, V>(self : BpTree<K, V>) : DoubleEndedIter<K> {
        DoubleEndedIter.map(
            entries(self),
            func(kv : (K, V)) : K {
                kv.0;
            },
        );
    };

    public func vals<K, V>(self : BpTree<K, V>) : DoubleEndedIter<V> {
        DoubleEndedIter.map(
            entries(self),
            func(kv : (K, V)) : V {
                kv.1;
            },
        );
    };

    // Returns the leaf node and rank of the first element in the leaf node
    func get_leaf_node_and_rank<K, V>(self : BpTree<K, V>, cmp : CmpFn<K>, key : K) : (Leaf<K, V>, Nat) {

        let root = switch (self.root) {
            case (#branch(node)) node;
            case (#leaf(node)) return (node, node.count);
        };

        var rank = root.subtree_size;

        func get_node(parent : Branch<K, V>, key : K) : Leaf<K, V> {
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

    /// Returns the rank of the given key in the tree
    ///
    /// The rank is 0 indexed so the first element in the tree has rank 0
    ///
    /// If the key does not exist in the tree, then the fn returns the rank
    /// of the key if it were to be inserted.
    public func getRank<K, V>(self : BpTree<K, V>, cmp : CmpFn<K>, key : K) : Nat {
        let (leaf_node, rank) = get_leaf_node_and_rank<K, V>(self, cmp, key);
        let i = ArrayMut.binary_search<(K, V), K>(leaf_node.kvs, Utils.adapt_cmp(cmp), key, leaf_node.count);

        if (i < 0) {
            return rank + (Int.abs(i) - 1 : Nat);
        };

        rank + Int.abs(i);
    };

    func get_leaf_node_by_rank<K, V>(self : BpTree<K, V>, rank : Nat) : (Leaf<K, V>, Nat) {
        let root = switch (self.root) {
            case (#branch(node)) node;
            case (#leaf(leaf)) return (leaf, rank);
        };

        var search_rank = rank;

        func get_node(parent : Branch<K, V>) : Leaf<K, V> {
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

    /// Returns the key-value pair at the given rank.
    /// Returns null if the rank is greater than the size of the tree.
    public func getByRank<K, V>(self : BpTree<K, V>, rank : Nat) : (K, V) {
        if (rank >= self.size) return Debug.trap("getByRank: rank is greater than the size of the tree");
        let (leaf_node, i) = get_leaf_node_by_rank(self, rank);

        assert i < leaf_node.count;

        let ?entry = leaf_node.kvs[i] else Debug.trap("getByRank: accessed a null value");
        entry;
    };

    /// Returns an iterator over the entries of the tree in the range [start, end]
    /// Where the range is defined by the ranks of the given start and end keys
    public func range(self : BpTree<Nat, Nat>, start : Nat, end : Nat) : DoubleEndedIter<(Nat, Nat)> {
        let (start_node, start_node_rank) = get_leaf_node_by_rank(self, start);
        let (end_node, end_node_rank) = get_leaf_node_by_rank(self, end);

        let start_index = start_node_rank : Nat;
        let end_index = end_node_rank + 1 : Nat; // + 1 because the end index is exclusive

        new_iterator<Nat, Nat>(start_node, start_index, end_node, end_index);
    };

    /// Returns an iterator over the entries of the tree in the range [start, end]
    /// The iterator is inclusive of start and end
    /// If the start key does not exist in the tree then the iterator will start from next key greater than start
    /// If the end key does not exist in the tree then the iterator will end at the last key less than end
    public func scan<K, V>(self : BpTree<K, V>, cmp : CmpFn<K>, start : K, end : K) : DoubleEndedIter<(K, V)> {
        let left_node = get_leaf_node<K, V>(self, cmp, start);
        let start_index = ArrayMut.binary_search<(K, V), K>(left_node.kvs, Utils.adapt_cmp(cmp), start, left_node.count);

        // if start_index is negative then the element was not found
        // moreover if start_index is negative then abs(i) - 1 is the index of the first element greater than start
        var i = if (start_index >= 0) Int.abs(start_index) else Int.abs(start_index) - 1 : Nat;

        let right_node = get_leaf_node<K, V>(self, cmp, end);
        let end_index = ArrayMut.binary_search<(K, V), K>(right_node.kvs, Utils.adapt_cmp(cmp), end, right_node.count);
        var j = if (end_index >= 0) Int.abs(end_index) + 1 else Int.abs(end_index) - 1 : Nat;

        new_iterator(left_node, i, right_node, j);
    };

    public func toLeafNodes<K, V>(self : BpTree<K, V>) : [[?(K, V)]] {
        var node = ?self.root;
        let buffer = Buffer.Buffer<[?(K, V)]>(self.size);

        var leaf_node : ?Leaf<K, V> = ?get_min_leaf_node(self);

        label _loop loop {
            switch (leaf_node) {
                case (?leaf) {
                    buffer.add(Array.freeze<?(K, V)>(leaf.kvs));
                    leaf_node := leaf.next;
                };
                case (_) break _loop;
            };
        };

        Buffer.toArray(buffer);
    };

    public func toNodeKeys<K, V>(self : BpTree<K, V>) : [[(Nat, [?K])]] {
        var nodes = BufferDeque.fromArray<?Node<K, V>>([?self.root]);
        let buffer = Buffer.Buffer<[(Nat, [?K])]>(self.size / 2);

        while (nodes.size() > 0) {
            let row = Buffer.Buffer<(Nat, [?K])>(nodes.size());

            for (_ in Iter.range(1, nodes.size())) {
                let ?node = nodes.popFront() else Debug.trap("toNodeKeys: accessed a null value");

                switch (node) {
                    case (? #branch(node)) {
                        let node_buffer = Buffer.Buffer<?K>(node.keys.size());
                        for (key in node.keys.vals()) {
                            node_buffer.add(key);
                        };

                        for (child in node.children.vals()) {
                            nodes.addBack(child);
                        };

                        row.add((node.index, Buffer.toArray(node_buffer)));
                    };
                    case (_) {};
                };
            };

            buffer.add(Buffer.toArray(row));
        };

        Buffer.toArray(buffer);
    };

    //Cursor.Cursor<K, V>

    /// Returns a cursor pointing to the first element in the tree
    public func cursorAtFirst<K, V>(self : BpTree<K, V>, cmp : CmpFn<K>) : Cursor<K, V> {
        let leaf_node = get_min_leaf_node(self);
        var i = 0;

        Cursor.Cursor(self, cmp, leaf_node, i);
    };

    /// Returns a cursor pointing to the last element in the tree
    public func cursorAtLast<K, V>(self : BpTree<K, V>, cmp : CmpFn<K>) : Cursor<K, V> {
        let leaf_node = get_max_leaf_node(self);
        var i = leaf_node.count - 1 : Nat;

        Cursor.Cursor(self, cmp, leaf_node, i);
    };

    /// Returns a cursor pointing to the given key.
    /// This function returns a Result because it is not guaranteed that the key exists in the tree.
    /// The function returns #ok(cursor) if the key exists and #err("key not found") otherwise.
    ///
    /// Consider using [cursorAtUpperBound](#cursorAtUpperBound) or [cursorAtLowerBound](#cursorAtLowerBound)
    /// if you want to get a cursor that falls back to the upper or lower bound of the given key instead of returning an error
    public func cursorAtKey<K, V>(self : BpTree<K, V>, cmp : CmpFn<K>, key : K) : Result<Cursor<K, V>, Text> {
        let leaf_node = get_leaf_node(self, cmp, key);
        let i = ArrayMut.binary_search<(K, V), K>(leaf_node.kvs, Utils.adapt_cmp(cmp), key, leaf_node.count);

        if (i < 0) {
            return #err("key not found");
        };

        let cursor = Cursor.Cursor<K, V>(self, cmp, leaf_node, Int.abs(i));
        #ok(cursor);
    };

    /// Returns a cursor pointing to the element that is less than or equal to the given key
    /// In other words, it returns a cursor pointing to an element that is upper bounded by the given key
    public func cursorAtUpperBound<K, V>(self : BpTree<K, V>, cmp : CmpFn<K>, key : K) : Cursor<K, V> {
        var leaf_node = get_leaf_node(self, cmp, key);
        let i = ArrayMut.binary_search<(K, V), K>(leaf_node.kvs, Utils.adapt_cmp(cmp), key, leaf_node.count);

        let index = if (i < 0) Int.abs(i + 1) else Int.abs(i);

        // add function to move to the previous element
        Cursor.Cursor<K, V>(self, cmp, leaf_node, index);
    };

    /// Returns a cursor pointing to the element that is greater than or equal to the given key
    /// In other words, it returns a cursor pointing to an element that is lower bounded by the given key
    public func cursorAtLowerBound<K, V>(self : BpTree<K, V>, cmp : CmpFn<K>, key : K) : Cursor<K, V> {
        var leaf_node = get_leaf_node(self, cmp, key);
        let i = ArrayMut.binary_search<(K, V), K>(leaf_node.kvs, Utils.adapt_cmp(cmp), key, leaf_node.count);

        var index = if (i < 0) (Int.abs(i) - 1 : Nat) else Int.abs(i);

        if (index == leaf_node.count) {
            switch (leaf_node.next) {
                case (?next) {
                    leaf_node := next;
                    index := 0;
                };
                case (_) {};
            };
        };

        Cursor.Cursor<K, V>(self, cmp, leaf_node, index);
    };

};
