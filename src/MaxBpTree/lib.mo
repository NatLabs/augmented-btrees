import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Order "mo:base/Order";
import Option "mo:base/Option";
import Int "mo:base/Int";
import Iter "mo:base/Iter";

import T "Types";
import InternalTypes "../internal/Types";
import InternalMethods "../internal/Methods";
import BpTree "../BpTree";
import ArrayMut "../internal/ArrayMut";
import InternalLeaf "../internal/Leaf";

import Leaf "Leaf";
import Branch "Branch";
import DoubleEndedIter "../internal/DoubleEndedIter";
import Common "Common";

module MaxBpTree {

    public type MaxBpTree<K, V> = T.MaxBpTree<K, V>;
    public type Node<K, V> = T.Node<K, V>;
    public type Leaf<K, V> = T.Leaf<K, V>;
    public type Branch<K, V> = T.Branch<K, V>;
    type CommonFields<K, V> = T.CommonFields<K, V>;
    type CommonNodeFields<K, V> = T.CommonNodeFields<K, V>;
    type MultiCmpFn<A, B> = InternalTypes.MultiCmpFn<A, B>;
    type CmpFn<A> = InternalTypes.CmpFn<A>;
    type MaxField<K, V> = T.MaxField<K, V>;

    type Iter<A> = Iter.Iter<A>;
    type Order = Order.Order;
    type DoubleEndedIter<A> = DoubleEndedIter.DoubleEndedIter<A>;

    public func new<K, V>(_order : ?Nat) : MaxBpTree<K, V> {
        let order = Option.get(_order, 32);

        assert order >= 4 and order <= 512;

        let leaf_node = Leaf.new<K, V>(order, 0, null, func() : Nat = 0);

        {
            order;
            var root = #leaf(leaf_node);
            var size = 0;
            var next_id = 1;
        };
    };

    /// Returns the value associated with the given key.
    /// If the key is not in the tree, it returns null.
    ///
    /// #### Examples
    /// ```motoko
    ///     let arr = [('A', 1), ('B', 2), ('C', 3)];
    ///     let max_bp_tree = MaxBpTree.fromArray<Char, Nat>(null, arr, Char.compare, Nat.compare);
    ///
    ///     assert MaxBpTree.get(max_bp_tree, Char.compare, 'A') == 1;
    ///     assert MaxBpTree.get(max_bp_tree, Char.compare, 'D') == null;
    /// ```
    public func get<K, V>(self : MaxBpTree<K, V>, cmp : CmpFn<K>, key : K) : ?V {
        InternalMethods.get(self, cmp, key);
    };

    /// Returns the largest key in the tree that is less than or equal to the given key.
    public func getFloor<K, V>(self : MaxBpTree<K, V>, cmp : CmpFn<K>, key : K) : ?(K, V) {
        InternalMethods.get_floor<K, V, MaxField<K, V>>(self, cmp, key);
    };

    /// Returns the smallest key in the tree that is greater than or equal to the given key.
    public func getCeiling<K, V>(self : MaxBpTree<K, V>, cmp : CmpFn<K>, key : K) : ?(K, V) {
        InternalMethods.get_ceiling<K, V, MaxField<K, V>>(self, cmp, key);
    };

    /// Inserts the given key-value pair into the tree.
    /// If the key already exists in the tree, it replaces the value and returns the old value.
    /// Otherwise, it returns null.
    ///
    /// #### Examples
    /// ```motoko
    ///     let max_bp_tree = MaxBpTree.new<Text, Nat>(?32);
    ///
    ///     assert MaxBpTree.insert(max_bp_tree, Text.compare, "id", 1) == null;
    ///     assert MaxBpTree.insert(max_bp_tree, Text.compare, "id", 2) == ?1;
    /// ```
    // add max-value update during replace                                                                                                                                                                                                  
    public func insert<K, V>(max_bp_tree : MaxBpTree<K, V>, cmp_key : CmpFn<K>, cmp_val : CmpFn<V>, key : K, val : V) : ?V {

        let update_leaf_fields = Common.update_leaf_fields<K, V>(cmp_val);
        let update_branch_fields = Common.update_branch_fields<K, V>(cmp_val);

        func reset_max_fields(fields : MaxField<K, V>) {
            fields.max_val := null;
            fields.max_key := null;
            fields.max_index := null;
        };

        func inc_branch_subtree_size(branch : Branch<K, V>, child_index: Nat) {
            branch.subtree_size += 1;

            update_leaf_fields(branch.fields, child_index, key, val);
        };

        func decrement_branch_subtree_size(branch : Branch<K, V>) {
            branch.subtree_size -= 1;
        };

        func adapt_cmp<K, V>(cmp_key : T.CmpFn<K>) : InternalTypes.MultiCmpFn<K, (K, V)> {
            func(a : K, b : (K, V)) : Order {
                cmp_key(a, b.0);
            };
        };

        func gen_id() : Nat = InternalMethods.gen_id(max_bp_tree);

        let leaf_node = InternalMethods.get_leaf_node_and_update_branch_path<K, V, MaxField<K, V>>(max_bp_tree, cmp_key, key, inc_branch_subtree_size);
        let entry = (key, val);

        let int_elem_index = ArrayMut.binary_search<K, (K, V)>(leaf_node.kvs, adapt_cmp(cmp_key), key, leaf_node.count);
        let elem_index = if (int_elem_index >= 0) Int.abs(int_elem_index) else Int.abs(int_elem_index + 1);

        let prev_value = if (int_elem_index >= 0) {
            let ?kv = leaf_node.kvs[elem_index] else Debug.trap("1. insert: accessed a null value while replacing a key-value pair");
            leaf_node.kvs[elem_index] := ?entry;

            // undoes the update to subtree count for the nodes on the path to the root when replacing a key-value pair
            InternalMethods.update_branch_path_from_leaf_to_root<K, V, MaxField<K, V>>(max_bp_tree, leaf_node, decrement_branch_subtree_size);

            return ?kv.1;
        } else {
            null;
        };

        if (leaf_node.count < max_bp_tree.order) {
            // shift elems to the right and insert the new key-value pair
            var j = leaf_node.count;

            while (j > elem_index) {
                leaf_node.kvs[j] := leaf_node.kvs[j - 1];
                j -= 1;
            };

            leaf_node.kvs[elem_index] := ?entry;
            leaf_node.count += 1;

            max_bp_tree.size += 1;

            update_leaf_fields(leaf_node.fields, elem_index, key, val);

            return prev_value;
        };

        // split leaf node
        let right_leaf_node = Leaf.split<K, V>(leaf_node, elem_index, entry, gen_id, reset_max_fields, update_leaf_fields);

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

            if (parent.count < max_bp_tree.order) {
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

                max_bp_tree.size += 1;

                update_branch_fields(parent.fields, right_index, right_node);

                return prev_value;

            } else {

                let median = (parent.count / 2) + 1; // include inserted key-value pair
                let prev_subtree_size = parent.subtree_size;

                let split_node = Branch.split(parent, right_node, right_index, right_key, gen_id, reset_max_fields, update_branch_fields);

                let ?first_key = InternalMethods.extract(split_node.keys, split_node.keys.size() - 1 : Nat) else Debug.trap("4. insert: accessed a null value in first key of branch");
                right_key := first_key;

                left_node := #branch(parent);
                right_node := #branch(split_node);

                right_index := split_node.index;
                opt_parent := split_node.parent;

                subtree_diff := prev_subtree_size - parent.subtree_size;
            };
        };

        let children = Array.init<?Node<K, V>>(max_bp_tree.order, null);
        children[0] := ?left_node;
        children[1] := ?right_node;

        let root_node = Branch.new<K, V>(max_bp_tree, null, ?children, gen_id, update_branch_fields);
        root_node.keys[0] := ?right_key;

        max_bp_tree.root := #branch(root_node);
        max_bp_tree.size += 1;

        prev_value;
    };

    /// Removes the key-value pair from the tree.
    /// If the key is not in the tree, it returns null.
    /// Otherwise, it returns the value associated with the key.
    ///
    /// #### Examples
    /// ```motoko
    ///     let arr = [('A', 1), ('B', 2), ('C', 3)];
    ///     let bptree = MaxBpTree.fromArray<Char, Nat>(null, arr, Char.compare, Nat.compare);
    ///
    ///     assert MaxBpTree.remove(bptree, Char.compare, Nat.compare, 'A') == ?1;
    ///     assert MaxBpTree.remove(bptree, Char.compare, Nat.compare, 'D') == null;
    /// ```
    public func remove<K, V>(self : MaxBpTree<K, V>, cmp_key : CmpFn<K>, cmp_val: CmpFn<V>, key : K) : ?V {
        func inc_branch_subtree_size(branch : Branch<K, V>) {
            branch.subtree_size += 1;
        };

        let update_leaf_fields = Common.update_leaf_fields<K, V>(cmp_val);
        let update_branch_fields = Common.update_branch_fields<K, V>(cmp_val);

        func reset_max_fields(fields : MaxField<K, V>) {
            fields.max_val := null;
            fields.max_key := null;
            fields.max_index := null;
        };

        func decrement_branch_subtree_size(branch : Branch<K, V>, index : Nat) {
            branch.subtree_size -= 1;
        };

        func calc_max_val(branch : Branch<K, V>) : Bool {
            let ?prev_max_key = branch.fields.max_key else Debug.trap("remove (calc_max_val): should have a max key");
            let ?prev_max_index = branch.fields.max_index else Debug.trap("remove (calc_max_val): should have a max index");

            if (cmp_key(prev_max_key, key) == #equal) {
                reset_max_fields(branch.fields);
                
                label _loop
                for (i in Iter.range(0, branch.count - 1)) {

                    let ?child = branch.children[i] else Debug.trap("1. remove: accessed a null value");

                    update_branch_fields(branch.fields, i, child);
                };

                return true;
            };

            false;
        };

        func adapt_cmp<K, V>(cmp_key : T.CmpFn<K>) : InternalTypes.MultiCmpFn<K, (K, V)> {
            func(a : K, b : (K, V)) : Order {
                cmp_key(a, b.0);
            };
        };

        let leaf_node = InternalMethods.get_leaf_node_and_update_branch_path(self, cmp_key, key, decrement_branch_subtree_size);

        let int_elem_index = ArrayMut.binary_search(leaf_node.kvs, adapt_cmp(cmp_key), key, leaf_node.count);
        let elem_index = if (int_elem_index >= 0) Int.abs(int_elem_index) else {
            InternalMethods.update_branch_path_from_leaf_to_root(self, leaf_node, inc_branch_subtree_size);
            return null;
        };
        // remove parent key as well
        let ?entry = ArrayMut.remove(leaf_node.kvs, elem_index, leaf_node.count) else Debug.trap("1. remove: accessed a null value");

        let deleted = entry.1;
        self.size -= 1;
        leaf_node.count -= 1;

        let ?max_key = leaf_node.fields.max_key else return Debug.trap("remove: should have a max key");

        if (cmp_key(max_key, key) == #equal) {
            reset_max_fields(leaf_node.fields);

            for (i in Iter.range(0, leaf_node.count - 1)) {
                let ?kv = leaf_node.kvs[i] else Debug.trap("2. remove: accessed a null value");
                update_leaf_fields(leaf_node.fields, i, kv.0, kv.1);
            };
        };

        InternalMethods.update_partial_branch_path_from_leaf_to_root(self, leaf_node, calc_max_val);

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

        InternalLeaf.redistribute_keys(leaf_node, ?reset_max_fields, ?update_leaf_fields, ?update_branch_fields);

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

        InternalLeaf.merge(left_node, right_node, ?update_leaf_fields, ?update_branch_fields);

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
            Branch.redistribute_keys(branch_node, reset_max_fields, update_branch_fields);

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

            Branch.merge(left_node, right_node, update_branch_fields);

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

    /// Create a new Max Value B+ tree from the given entries.
    ///
    /// #### Inputs
    /// - `order` - the maximum number of children a node can have.
    /// - `entries` - an iterator over the entries to insert into the tree.
    /// - `cmp` - the comparison function to use for ordering the keys.
    ///
    /// #### Examples
    /// ```motoko
    ///     let entries = [('A', 1), ('B', 2), ('C', 3)].vals();
    ///     let max_bp_tree = InternalMethods.fromEntries<Char, Nat>(null, entries, Char.compare);
    /// ```

    public func fromEntries<K, V>(order : ?Nat, entries : Iter<(K, V)>, cmp_key : CmpFn<K>, cmp_val: CmpFn<V>) : MaxBpTree<K, V> {
        let max_bp_tree = MaxBpTree.new<K, V>(order);

        for ((k, v) in entries) {
            ignore insert<K, V>(max_bp_tree, cmp_key, cmp_val, k, v);
        };

        max_bp_tree;
    };

    /// Create a new Max Value B+ tree from the given array of key-value pairs.
    ///
    /// #### Inputs
    /// - `order` - the maximum number of children a node can have.
    /// - `arr` - the array of key-value pairs to insert into the tree.
    /// - `cmp` - the comparison function to use for ordering the keys.
    ///
    /// #### Examples
    /// ```motoko
    ///    let arr = [('A', 1), ('B', 2), ('C', 3)];
    ///    let max_bp_tree = MaxBpTree.fromArray<Char, Nat>(null, arr, Char.compare, Nat.compare);
    /// ```
    public func fromArray<K, V>(order : ?Nat, arr : [(K, V)], cmp_key : CmpFn<K>, cmp_val: CmpFn<V>) : MaxBpTree<K, V> {
        let max_bp_tree = MaxBpTree.new<K, V>(order);

        for (kv in arr.vals()) {
            let (k, v) = kv;
            ignore MaxBpTree.insert(max_bp_tree, cmp_key, cmp_val, k, v);
        };

        max_bp_tree;
    };

    /// Returns a sorted array of the key-value pairs in the tree.
    ///
    /// #### Examples
    /// ```motoko
    ///     let arr = [('A', 1), ('B', 2), ('C', 3)];
    ///     let max_bp_tree = MaxBpTree.fromArray<Char, Nat>(null, arr, Char.compare, Nat.compare);
    ///     assert MaxBpTree.toArray(max_bp_tree) == arr;
    /// ```
    public func toArray<K, V>(self : MaxBpTree<K, V>) : [(K, V)] {
        InternalMethods.to_array<K, V, MaxField<K, V>>(self);
    };

    /// Returns the size of the Max Value B+ tree.
    ///
    /// #### Examples
    /// ```motoko
    ///     let arr = [('A', 1), ('B', 2), ('C', 3)];
    ///     let max_bp_tree = MaxBpTree.fromArray<Char, Nat>(null, arr, Char.compare, Nat.compare);
    ///
    ///     assert MaxBpTree.size(max_bp_tree) == 3;
    /// ```
    public func size<K, V>(self : MaxBpTree<K, V>) : Nat {
        self.size;
    };

    /// Returns the entry with the max value in the tree.
    /// If the tree is empty, it returns null.
    ///
    /// #### Examples
    /// ```motoko
    ///     let arr = [('A', 1), ('B', 2), ('C', 3)];
    ///     let max_bp_tree = MaxBpTree.fromArray<Char, Nat>(null, arr, Char.compare, Nat.compare);
    ///
    ///     assert MaxBpTree.maxValue(max_bp_tree) == ?('C', 3);
    /// ```
    public func maxValue<K, V>(self : MaxBpTree<K, V>) : ?(K, V) {
        switch(self.root) {
            case (#leaf(node) or #branch(node) : CommonNodeFields<K, V>) {
                let ?max_key = node.fields.max_key else return null;
                let ?max_val = node.fields.max_val else return null;

                ?(max_key, max_val);
            };
        };
    };

    /// Returns the minimum key-value pair in the tree.
    /// If the tree is empty, it returns null.
    ///
    /// #### Examples
    /// ```motoko
    ///     let arr = [('A', 1), ('B', 2), ('C', 3)];
    ///     let max_bp_tree = MaxBpTree.fromArray<Char, Nat>(null, arr, Char.compare, Nat.compare);
    ///
    ///     assert MaxBpTree.min(max_bp_tree) == ?('A', 1);
    /// ```
    public func min<K, V>(self : MaxBpTree<K, V>) : ?(K, V) {
        InternalMethods.min(self);
    };

    /// Returns the maximum key-value pair in the tree.
    /// If the tree is empty, it returns null.
    ///
    /// #### Examples
    /// ```motoko
    ///     let arr = [('A', 1), ('B', 2), ('C', 3)];
    ///     let max_bp_tree = MaxBpTree.fromArray<Char, Nat>(null, arr, Char.compare, Nat.compare);
    ///
    ///     assert MaxBpTree.max(max_bp_tree) == ?('C', 3);
    /// ```
    public func max<K, V>(self : MaxBpTree<K, V>) : ?(K, V) {
        InternalMethods.max(self);
    };

        /// Removes the minimum key-value pair in the tree and returns it.
    /// If the tree is empty, it returns null.
    /// 
    /// #### Examples
    /// ```motoko
    ///     let arr = [('A', 1), ('B', 2), ('C', 3)];
    ///     let bptree = MaxBpTree.fromArray<Char, Nat>(null, arr, Char.compare, Nat.compare);
    ///
    ///     assert MaxBpTree.removeMin(bptree, Char.compare) == ?('A', 1);
    /// ```
    public func removeMin<K, V>(self : MaxBpTree<K, V>, cmp_key: CmpFn<K>, cmp_val: CmpFn<V>) : ?(K, V) {
        let ?(min_key, _) = InternalMethods.min(self) else return null;

        let ?v = remove(self, cmp_key, cmp_val, min_key) else return null;

        return ?(min_key, v);        
    };

    /// Removes the maximum key-value pair in the tree and returns it.
    /// If the tree is empty, it returns null.
    ///
    /// #### Examples
    /// ```motoko
    ///     let arr = [('A', 1), ('B', 2), ('C', 3)];
    ///     let bptree = MaxBpTree.fromArray<Char, Nat>(null, arr, Char.compare, Nat.compare);
    ///
    ///     assert MaxBpTree.removeMax(bptree, Char.compare, Nat.compare) == ?('C', 3);
    /// ```
    public func removeMax<K, V>(self : MaxBpTree<K, V>, cmp_key: CmpFn<K>, cmp_val: CmpFn<V>) : ?(K, V) {
        let ?(max_key, _) = InternalMethods.max(self) else return null;

        let ?v = remove(self, cmp_key, cmp_val, max_key) else return null;

        return ?(max_key, v);
    };

    /// Removes the entry with the max value in the tree.
    /// If the tree is empty, it returns null.
    ///
    /// #### Examples
    /// ```motoko
    ///     let arr = [('A', 1), ('B', 3), ('C', 2)];
    ///     let max_bp_tree = MaxBpTree.fromArray<Char, Nat>(null, arr, Char.compare, Nat.compare);
    ///
    ///     assert MaxBpTree.removeMaxValue(max_bp_tree, Char.compare, Nat.compare) == ?('B', 3);
    /// ```
    public func removeMaxValue<K, V>(self : MaxBpTree<K, V>, cmp_key: CmpFn<K>, cmp_val: CmpFn<V>) : ?(K, V) {
        let ?(max_key, _) = MaxBpTree.maxValue(self) else return null;

        let ?v = remove(self, cmp_key, cmp_val, max_key) else return null;

        return ?(max_key, v);
    };


    /// Returns a double ended iterator over the entries of the tree.
    public func entries<K, V>(max_bp_tree : MaxBpTree<K, V>) : DoubleEndedIter<(K, V)> {
        InternalMethods.entries(max_bp_tree);
    };

    /// Returns a double ended iterator over the keys of the tree.
    public func keys<K, V>(self : MaxBpTree<K, V>) : DoubleEndedIter<K> {
        InternalMethods.keys(self);
    };

    /// Returns a double ended iterator over the values of the tree.
    public func vals<K, V>(self : MaxBpTree<K, V>) : DoubleEndedIter<V> {
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
    ///     let max_bp_tree = MaxBpTree.fromArray<Char, Nat>(null, arr, Char.compare, Nat.compare);
    ///
    ///     assert MaxBpTree.getRank(max_bp_tree, Char.compare, 'B') == 1;
    ///     assert MaxBpTree.getRank(max_bp_tree, Char.compare, 'D') == 3;
    /// ```
    public func getRank<K, V>(self : MaxBpTree<K, V>, cmp : CmpFn<K>, key : K) : Nat {
        InternalMethods.get_rank(self, cmp, key);
    };

    /// Returns the key-value pair at the given rank.
    /// Returns null if the rank is greater than the size of the tree.
    ///
    /// #### Examples
    /// ```motoko
    ///     let arr = [('A', 1), ('B', 2), ('C', 3)];
    ///     let max_bp_tree = MaxBpTree.fromArray<Char, Nat>(null, arr, Char.compare, Nat.compare);
    ///
    ///     assert MaxBpTree.getByRank(max_bp_tree, 0) == ('A', 1);
    ///     assert MaxBpTree.getByRank(max_bp_tree, 1) == ('B', 2);
    /// ```
    public func getByRank<K, V>(self : MaxBpTree<K, V>, rank : Nat) : (K, V) {
        InternalMethods.get_by_rank(self, rank);
    };

    /// Returns an iterator over the entries of the tree in the range [start, end].
    /// The range is defined by the ranks of the start and end keys
    public func range<K, V>(self : MaxBpTree<K, V>, start : Nat, end : Nat) : DoubleEndedIter<(K, V)> {
        InternalMethods.range(self, start, end);
    };

    /// Returns an iterator over the entries of the tree in the range [start, end].
    /// The iterator is inclusive of start and end.
    ///
    /// If the start key does not exist in the tree then the iterator will start from next key greater than start.
    /// If the end key does not exist in the tree then the iterator will end at the last key less than end.
    public func scan<K, V>(self : MaxBpTree<K, V>, cmp : CmpFn<K>, start : K, end : K) : DoubleEndedIter<(K, V)> {
        InternalMethods.scan(self, cmp, start, end);
    };

};
