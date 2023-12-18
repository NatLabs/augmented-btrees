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
import InternalMethods "../internal/Methods";
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
    type CommonFields<K, V> = T.CommonFields<K, V>;
    type CommonNodeFields<K, V> = T.CommonNodeFields<K, V>;
    type MultiCmpFn<A, B> = (A, B) -> Order;

    // public func new2<K, V>(): T.BpTreeV2<K, V> {
    //     new<K, V>();
    // };

    /// Create a new B+ tree with the given order.
    /// The order is the maximum number of children a node can have.
    /// The order must be between 4 and 512 inclusive.
    ///
    /// #### Examples
    /// ```motoko
    /// let bptree = BpTree.new<Char, Nat>(?32);
    /// ```
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

    /// Create a new B+ tree from the given entries.
    ///
    /// #### Inputs
    /// - `order` - the maximum number of children a node can have.
    /// - `entries` - an iterator over the entries to insert into the tree.
    /// - `cmp` - the comparison function to use for ordering the keys.
    ///
    /// #### Examples
    /// ```motoko
    ///     let entries = [('A', 1), ('B', 2), ('C', 3)].vals();
    ///     let bptree = BpTree.fromEntries<Char, Nat>(null, entries, Char.compare);
    /// ```

    public func fromEntries<K, V>(order : ?Nat, entries : Iter<(K, V)>, cmp : CmpFn<K>) : BpTree<K, V> {
        let bptree = BpTree.new<K, V>(order);

        for ((k, v) in entries) {
            ignore insert<K, V>(bptree, cmp, k, v);
        };

        bptree;
    };

    /// Create a new B+ tree from the given array of key-value pairs.
    ///
    /// #### Inputs
    /// - `order` - the maximum number of children a node can have.
    /// - `arr` - the array of key-value pairs to insert into the tree.
    /// - `cmp` - the comparison function to use for ordering the keys.
    ///
    /// #### Examples
    /// ```motoko
    ///    let arr = [('A', 1), ('B', 2), ('C', 3)];
    ///    let bptree = BpTree.fromArray<Char, Nat>(null, arr, Char.compare);
    /// ```
    public func fromArray<K, V>(order : ?Nat, arr : [(K, V)], cmp : CmpFn<K>) : BpTree<K, V> {
        let bptree = BpTree.new<K, V>(order);

        for (kv in arr.vals()) {
            let (k, v) = kv;
            ignore insert(bptree, cmp, k, v);
        };

        bptree;
    };

    /// Returns a sorted array of the key-value pairs in the tree.
    ///
    /// #### Examples
    /// ```motoko
    ///     let arr = [('A', 1), ('B', 2), ('C', 3)];
    ///     let bptree = BpTree.fromArray<Char, Nat>(null, arr, Char.compare);
    ///     assert BpTree.toArray(bptree) == arr;
    /// ```
    public func toArray<K, V>(self : BpTree<K, V>) : [(K, V)] {
        InternalMethods.to_array(self);
    };

    /// Returns the size of the B+ tree.
    ///
    /// #### Examples
    /// ```motoko
    ///     let arr = [('A', 1), ('B', 2), ('C', 3)];
    ///     let bptree = BpTree.fromArray<Char, Nat>(null, arr, Char.compare);
    ///
    ///     assert BpTree.size(bptree) == 3;
    /// ```
    public func size<K, V>(self : BpTree<K, V>) : Nat {
        self.size;
    };

    /// Returns the value associated with the given key.
    /// If the key is not in the tree, it returns null.
    ///
    /// #### Examples
    /// ```motoko
    ///     let arr = [('A', 1), ('B', 2), ('C', 3)];
    ///     let bptree = BpTree.fromArray<Char, Nat>(null, arr, Char.compare);
    ///
    ///     assert BpTree.get(bptree, Char.compare, 'A') == 1;
    ///     assert BpTree.get(bptree, Char.compare, 'D') == null;
    /// ```
    public func get<K, V>(self : BpTree<K, V>, cmp : CmpFn<K>, key : K) : ?V {
        InternalMethods.get(self, cmp, key);
    };

    /// Returns the largest element in the B+Tree that is less than or equal to a given key.
    public func getFloor<K, V>(self : BpTree<K, V>, cmp : CmpFn<K>, key : K) : ?(K, V) {
        InternalMethods.get_floor(self, cmp, key);
    };

    /// Returns the smallest element in the B+Tree that is greater than or equal to a given key.
    public func getCeiling<K, V>(self : BpTree<K, V>, cmp : CmpFn<K>, key : K) : ?(K, V) {
        InternalMethods.get_ceiling(self, cmp, key);
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

    /// Inserts the given key-value pair into the tree.
    /// If the key already exists in the tree, it replaces the value and returns the old value.
    /// Otherwise, it returns null.
    ///
    /// #### Examples
    /// ```motoko
    ///     let bptree = BpTree.new<Text, Nat>(?32);
    ///
    ///     assert BpTree.insert(bptree, Text.compare, "id", 1) == null;
    ///     assert BpTree.insert(bptree, Text.compare, "id", 2) == ?1;
    /// ```
    public func insert<K, V>(self : BpTree<K, V>, cmp : CmpFn<K>, key : K, val : V) : ?V {
        func inc_branch_subtree_size(branch : Branch<K, V>, index: Nat) {
            branch.subtree_size += 1;
        };

        func decrement_branch_subtree_size(branch : Branch<K, V>) {
            branch.subtree_size -= 1;
        };

        func adapt_cmp<K, V>(cmp : T.CmpFn<K>) : InternalTypes.MultiCmpFn<K, (K, V)> {
            func(a : K, b : (K, V)) : Order {
                cmp(a, b.0);
            };
        };

        func gen_id() : Nat = InternalMethods.gen_id(self);

        let leaf_node = InternalMethods.get_leaf_node_and_update_branch_path(self, cmp, key, inc_branch_subtree_size);
        let entry = (key, val);

        let int_elem_index = ArrayMut.binary_search<K, (K, V)>(leaf_node.kvs, adapt_cmp(cmp), key, leaf_node.count);
        let elem_index = if (int_elem_index >= 0) Int.abs(int_elem_index) else Int.abs(int_elem_index + 1);

        let prev_value = if (int_elem_index >= 0) {
            let ?kv = leaf_node.kvs[elem_index] else Debug.trap("1. insert: accessed a null value while replacing a key-value pair");
            leaf_node.kvs[elem_index] := ?entry;

            // undoes the update to subtree count for the nodes on the path to the root when replacing a key-value pair
            InternalMethods.update_branch_path_from_leaf_to_root(self, leaf_node, decrement_branch_subtree_size);

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

        var opt_parent : ?Branch<K, V> = leaf_node.parent;
        var left_node : Node<K, V> = #leaf(leaf_node);
        var left_index = leaf_node.index;

        var right_index = right_leaf_node.index;
        let ?right_leaf_first_entry = right_leaf_node.kvs[0] else Debug.trap("2. insert: accessed a null value");
        var right_key = right_leaf_first_entry.0;
        var right_node : Node<K, V> = #leaf(right_leaf_node);

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
                        case ((? #branch(node) or ? #leaf(node)) : ?CommonNodeFields<K, V>) {
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

                let ?first_key = InternalMethods.extract(split_node.keys, split_node.keys.size() - 1 : Nat) else Debug.trap("4. insert: accessed a null value in first key of branch");
                right_key := first_key;

                left_node := #branch(parent);
                right_node := #branch(split_node);

                right_index := split_node.index;
                opt_parent := split_node.parent;

                subtree_diff := prev_subtree_size - parent.subtree_size;
            };
        };

        let children = Array.init<?Node<K, V>>(self.order, null);
        children[0] := ?left_node;
        children[1] := ?right_node;

        let root_node = Branch.new<K, V>(self.order, null, ?children, gen_id);
        root_node.keys[0] := ?right_key;

        self.root := #branch(root_node);
        self.size += 1;

        prev_value;
    };

    /// Removes the key-value pair from the tree.
    /// If the key is not in the tree, it returns null.
    /// Otherwise, it returns the value associated with the key.
    ///
    /// #### Examples
    /// ```motoko
    ///     let arr = [('A', 1), ('B', 2), ('C', 3)];
    ///     let bptree = BpTree.fromArray<Char, Nat>(null, arr, Char.compare);
    ///
    ///     assert BpTree.remove(bptree, Char.compare, 'A') == ?1;
    ///     assert BpTree.remove(bptree, Char.compare, 'D') == null;
    /// ```
    public func remove<K, V>(self : BpTree<K, V>, cmp : CmpFn<K>, key : K) : ?V {
        func inc_branch_subtree_size(branch : Branch<K, V>) {
            branch.subtree_size += 1;
        };

        func decrement_branch_subtree_size(branch : Branch<K, V>, index : Nat) {
            branch.subtree_size -= 1;
        };

        func adapt_cmp<K, V>(cmp : T.CmpFn<K>) : InternalTypes.MultiCmpFn<K, (K, V)> {
            func(a : K, b : (K, V)) : Order {
                cmp(a, b.0);
            };
        };
        let leaf_node = InternalMethods.get_leaf_node_and_update_branch_path(self, cmp, key, decrement_branch_subtree_size);

        let int_elem_index = ArrayMut.binary_search<K, (K, V)>(leaf_node.kvs, adapt_cmp(cmp), key, leaf_node.count);
        let elem_index = if (int_elem_index >= 0) Int.abs(int_elem_index) else {
            InternalMethods.update_branch_path_from_leaf_to_root(self, leaf_node, inc_branch_subtree_size);
            return null;
        };
        // remove parent key as well
        let ?entry : ?(K, V) = ArrayMut.remove(leaf_node.kvs, elem_index, leaf_node.count) else Debug.trap("1. remove: accessed a null value");

        let deleted = entry.1;
        self.size -= 1;
        leaf_node.count -= 1;

        let min_count = self.order / 2;

        let ?_parent = leaf_node.parent else return ?deleted; // if parent is null then leaf_node is the root
        var parent = _parent;

        func update_deleted_median_key(_parent : Branch<K, V>, index : Nat, deleted_key : K, next_key : K) {
            var parent = _parent;
            var i = index;

            while (i == 0) {
                i := parent.index;
                let ?__parent = parent.parent else return; // occurs when key is the first key in the tree
                parent := __parent;
            };

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

        var branch_node = parent;
        let ?__parent = branch_node.parent else {

            // update root node as this node does not have a parent
            // which means it is the root node
            if (branch_node.count == 1) {
                let ?child = branch_node.children[0] else Debug.trap("3. remove: accessed a null value");
                switch (child) {
                    case (#branch(node) or #leaf(node) : CommonNodeFields<K, V>) {
                        node.parent := null;
                    };
                };
                self.root := child;
            };

            return ?deleted;
        };

        parent := __parent;

        while (branch_node.count < min_count) {
            Branch.redistribute_keys(branch_node);

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

            branch_node := parent;
            let ?_parent = branch_node.parent else {
                // update root node if necessary
                if (branch_node.count == 1) {
                    let ?child = branch_node.children[0] else Debug.trap("3. remove: accessed a null value");
                    switch (child) {
                        case (#branch(node) or #leaf(node) : CommonNodeFields<K, V>) {
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

    /// Returns the minimum key-value pair in the tree.
    /// If the tree is empty, it returns null.
    ///
    /// #### Examples
    /// ```motoko
    ///     let arr = [('A', 1), ('B', 2), ('C', 3)];
    ///     let bptree = BpTree.fromArray<Char, Nat>(null, arr, Char.compare);
    ///
    ///     assert BpTree.min(bptree) == ?('A', 1);
    /// ```
    public func min<K, V>(self : BpTree<K, V>) : ?(K, V) {
        InternalMethods.min(self);
    };

    /// Returns the maximum key-value pair in the tree.
    /// If the tree is empty, it returns null.
    ///
    /// #### Examples
    /// ```motoko
    ///     let arr = [('A', 1), ('B', 2), ('C', 3)];
    ///     let bptree = BpTree.fromArray<Char, Nat>(null, arr, Char.compare);
    ///
    ///     assert BpTree.max(bptree) == ?('C', 3);
    /// ```
    public func max<K, V>(self : BpTree<K, V>) : ?(K, V) {
        InternalMethods.max(self);
    };

    /// Removes the minimum key-value pair in the tree and returns it.
    /// If the tree is empty, it returns null.
    /// 
    /// #### Examples
    /// ```motoko
    ///     let arr = [('A', 1), ('B', 2), ('C', 3)];
    ///     let bptree = BpTree.fromArray<Char, Nat>(null, arr, Char.compare);
    ///
    ///     assert BpTree.removeMin(bptree, Char.compare) == ?('A', 1);
    /// ```
    public func removeMin<K, V>(self : BpTree<K, V>, cmp: CmpFn<K>) : ?(K, V) {
        let ?(min_key, _) = InternalMethods.min(self) else return null;

        let ?v = remove(self, cmp, min_key) else return null;

        return ?(min_key, v);        
    };

    /// Removes the maximum key-value pair in the tree and returns it.
    /// If the tree is empty, it returns null.
    ///
    /// #### Examples
    /// ```motoko
    ///     let arr = [('A', 1), ('B', 2), ('C', 3)];
    ///     let bptree = BpTree.fromArray<Char, Nat>(null, arr, Char.compare);
    ///
    ///     assert BpTree.removeMax(bptree, Char.compare) == ?('C', 3);
    /// ```
    public func removeMax<K, V>(self : BpTree<K, V>, cmp: CmpFn<K>) : ?(K, V) {
        let ?(max_key, _) = InternalMethods.max(self) else return null;

        let ?v = remove(self, cmp, max_key) else return null;

        return ?(max_key, v);
    };

    /// Returns a double ended iterator over the entries of the tree.
    public func entries<K, V>(bptree : BpTree<K, V>) : DoubleEndedIter<(K, V)> {
        InternalMethods.entries(bptree);
    };

    /// Returns a double ended iterator over the keys of the tree.
    public func keys<K, V>(self : BpTree<K, V>) : DoubleEndedIter<K> {
        InternalMethods.keys(self);
    };

    /// Returns a double ended iterator over the values of the tree.
    public func vals<K, V>(self : BpTree<K, V>) : DoubleEndedIter<V> {
        InternalMethods.vals(self);
    };

    /// Returns the rank of the given key in the tree.
    /// The rank is 0 indexed so the first element in the tree has rank 0.
    ///
    /// If the key does not exist in the tree, then the fn returns the rank.
    /// of the key if it were to be inserted.
    ///
    /// #### Examples
    /// ```motoko
    ///     let arr = [('A', 1), ('B', 2), ('C', 3)];
    ///     let bptree = BpTree.fromArray<Char, Nat>(null, arr, Char.compare);
    ///
    ///     assert BpTree.getRank(bptree, Char.compare, 'B') == 1;
    ///     assert BpTree.getRank(bptree, Char.compare, 'D') == 3;
    /// ```
    public func getRank<K, V>(self : BpTree<K, V>, cmp : CmpFn<K>, key : K) : Nat {
        InternalMethods.get_rank(self, cmp, key);
    };

    /// Returns the key-value pair at the given rank.
    /// Returns null if the rank is greater than the size of the tree.
    ///
    /// #### Examples
    /// ```motoko
    ///     let arr = [('A', 1), ('B', 2), ('C', 3)];
    ///     let bptree = BpTree.fromArray<Char, Nat>(null, arr, Char.compare);
    ///
    ///     assert BpTree.getByRank(bptree, 0) == ('A', 1);
    ///     assert BpTree.getByRank(bptree, 1) == ('B', 2);
    /// ```
    public func getByRank<K, V>(self : BpTree<K, V>, rank : Nat) : (K, V) {
        InternalMethods.get_by_rank(self, rank);
    };

    /// Returns an iterator over the entries of the tree in the range [start, end].
    /// The range is defined by the ranks of the start and end keys
    public func range<K, V>(self : BpTree<K, V>, start : Nat, end : Nat) : DoubleEndedIter<(K, V)> {
        InternalMethods.range(self, start, end);
    };

    /// Returns an iterator over the entries of the tree in the range [start, end].
    /// The iterator is inclusive of start and end.
    ///
    /// If the start key does not exist in the tree then the iterator will start from next key greater than start.
    /// If the end key does not exist in the tree then the iterator will end at the last key less than end.
    public func scan<K, V>(self : BpTree<K, V>, cmp : CmpFn<K>, start : K, end : K) : DoubleEndedIter<(K, V)> {
        InternalMethods.scan(self, cmp, start, end);
    };
    

    public func toLeafNodes<K, V>(self : BpTree<K, V>) : [[?(K, V)]] {
        var node = ?self.root;
        let buffer = Buffer.Buffer<[?(K, V)]>(self.size);

        var leaf_node : ?Leaf<K, V> = ?InternalMethods.get_min_leaf_node(self);

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
        let leaf_node = InternalMethods.get_min_leaf_node(self);
        var i = 0;

        Cursor.Cursor(self, cmp, leaf_node, i);
    };

    /// Returns a cursor pointing to the last element in the tree
    public func cursorAtLast<K, V>(self : BpTree<K, V>, cmp : CmpFn<K>) : Cursor<K, V> {
        let leaf_node = InternalMethods.get_max_leaf_node(self);
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
        let leaf_node = InternalMethods.get_leaf_node(self, cmp, key);
        let i = ArrayMut.binary_search<K, (K, V)>(leaf_node.kvs, Utils.adapt_cmp(cmp), key, leaf_node.count);

        if (i < 0) {
            return #err("key not found");
        };

        let cursor = Cursor.Cursor<K, V>(self, cmp, leaf_node, Int.abs(i));
        #ok(cursor);
    };

    /// Returns a cursor pointing to the element that is less than or equal to the given key
    /// In other words, it returns a cursor pointing to an element that is upper bounded by the given key
    public func cursorAtUpperBound<K, V>(self : BpTree<K, V>, cmp : CmpFn<K>, key : K) : Cursor<K, V> {
        var leaf_node = InternalMethods.get_leaf_node(self, cmp, key);
        let i = ArrayMut.binary_search<K, (K, V)>(leaf_node.kvs, Utils.adapt_cmp(cmp), key, leaf_node.count);

        let index = if (i < 0) Int.abs(i + 1) else Int.abs(i);

        // add function to move to the previous element
        Cursor.Cursor<K, V>(self, cmp, leaf_node, index);
    };

    /// Returns a cursor pointing to the element that is greater than or equal to the given key
    /// In other words, it returns a cursor pointing to an element that is lower bounded by the given key
    public func cursorAtLowerBound<K, V>(self : BpTree<K, V>, cmp : CmpFn<K>, key : K) : Cursor<K, V> {
        var leaf_node = InternalMethods.get_leaf_node(self, cmp, key);
        let i = ArrayMut.binary_search<K, (K, V)>(leaf_node.kvs, Utils.adapt_cmp(cmp), key, leaf_node.count);

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
