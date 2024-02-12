import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Order "mo:base/Order";
import Option "mo:base/Option";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";

import BufferDeque "mo:buffer-deque/BufferDeque";
import T "Types";
import InternalTypes "../internal/Types";
import Methods "Methods";
import BpTree "../BpTree";
import ArrayMut "../internal/ArrayMut";

import Leaf "Leaf";
import Branch "Branch";
import DoubleEndedIter "../internal/DoubleEndedIter";
import Common "Common";
import Utils "../internal/Utils";

module MaxBpTree {

    public type MaxBpTree<K, V> = T.MaxBpTree<K, V>;
    public type Node<K, V> = T.Node<K, V>;
    public type BufferDeque<T> = BufferDeque.BufferDeque<T>;
    public type Leaf<K, V> = T.Leaf<K, V>;
    public type Branch<K, V> = T.Branch<K, V>;
    public type CommonFields<K, V> = T.CommonFields<K, V>;
    public type CommonNodeFields<K, V> = T.CommonNodeFields<K, V>;
    type MultiCmpFn<A, B> = InternalTypes.MultiCmpFn<A, B>;
    type CmpFn<A> = InternalTypes.CmpFn<A>;

    type Iter<A> = Iter.Iter<A>;
    type Order = Order.Order;
    public type DoubleEndedIter<A> = DoubleEndedIter.DoubleEndedIter<A>;

    public func new<K, V>(_order : ?Nat) : MaxBpTree<K, V> {
        let order = Option.get(_order, 32);

        assert order >= 4 and order <= 512;

        let leaf_node = Leaf.new<K, V>(order, 0, null, func() : Nat = 0, func(_ : V, _ : V) : Order = #equal);

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
        Methods.get(self, cmp, key);
    };

    /// Checks if the given key exists in the tree.
    public func has<K, V>(self : MaxBpTree<K, V>, cmp : CmpFn<K>, key : K) : Bool {
        Option.isSome(get(self, cmp, key));
    };

    /// Returns the largest key in the tree that is less than or equal to the given key.
    public func getFloor<K, V>(self : MaxBpTree<K, V>, cmp : CmpFn<K>, key : K) : ?(K, V) {
        Methods.get_floor<K, V>(self, cmp, key);
    };

    /// Returns the smallest key in the tree that is greater than or equal to the given key.
    public func getCeiling<K, V>(self : MaxBpTree<K, V>, cmp : CmpFn<K>, key : K) : ?(K, V) {
        Methods.get_ceiling<K, V>(self, cmp, key);
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
    public func insert(max_bp_tree : MaxBpTree<Nat, Nat>, cmp_key : CmpFn<Nat>, cmp_val : CmpFn<Nat>, key : Nat, val : Nat) : ?Nat {
        func inc_branch_subtree_size(branch : Branch<Nat, Nat>, child_index : Nat) {
            // increase the subtree size of every branch on the path to the leaf node
            branch.subtree_size += 1;

            // update the max value of the branch node if necessary
            // note:    this function selects the max value by comparing all the max values in the children
            //          of the branch node. However, since the max value of the child node storing the key-value
            //          pair we are removing has not yet computed its new max value, the value stored here is just
            //          a placeholder (or best possible option) until the new max value is computed.
            let ?max = branch.max else Debug.trap("insert(inc_branch_subtree_size): should have a max value");
            let (max_key, max_val, max_index) = max;

            if (cmp_key(max_key, key) == #equal and cmp_val(val, max_val) == #less) {
                branch.max := ?(key, val, child_index);

                label _loop for (i in Iter.range(0, branch.count - 1)) {

                    let ?child = branch.children[i] else Debug.trap("insert(inc_branch_subtree_size): accessed a null value");

                    if (i == max_index) {
                        let #branch(node) or #leaf(node) = child;
                        assert i == node.index;
                        let ?node_max = node.max else Debug.trap("insert(inc_branch_subtree_size): should have a max key");
                        assert cmp_key(node_max.1, max_val) == #equal;
                        continue _loop;
                    };

                    Common.update_branch_fields(branch, cmp_val, i, child);
                };
            } else {
                Common.update_leaf_fields(branch, cmp_val, child_index, key, val);
            };
        };

        let leaf_node = Methods.get_leaf_node_and_update_branch_path(max_bp_tree, cmp_key, key, inc_branch_subtree_size);

        _insert_in_leaf(max_bp_tree, cmp_key, cmp_val, leaf_node, key, val);

    };

    public func _insert_in_leaf(max_bp_tree : MaxBpTree<Nat, Nat>, cmp_key : CmpFn<Nat>, cmp_val : CmpFn<Nat>, leaf_node : Leaf<Nat, Nat>, key : Nat, val : Nat) : ?Nat {
        let int_elem_index = ArrayMut.binary_search(leaf_node.kvs, Utils.adapt_cmp(cmp_key), key, leaf_node.count);
        let elem_index = if (int_elem_index >= 0) Int.abs(int_elem_index) else Int.abs(int_elem_index + 1);

        if (int_elem_index >= 0 and int_elem_index < leaf_node.count) {
            _replace_at_leaf_index(max_bp_tree, cmp_key, cmp_val, leaf_node, elem_index, key, val, false);
        } else {
            _insert_at_leaf_index(max_bp_tree, cmp_key, cmp_val, leaf_node, elem_index, key, val, false);
        };
    };

    public func _replace_at_leaf_index(max_bp_tree : MaxBpTree<Nat, Nat>, cmp_key : CmpFn<Nat>, cmp_val : CmpFn<Nat>, leaf_node : Leaf<Nat, Nat>, elem_index : Nat, key : Nat, val : Nat, called_independently : Bool) : ?Nat {

        let ?kv = leaf_node.kvs[elem_index] else Debug.trap("1. insert: accessed a null value while replacing a key-value pair");
        leaf_node.kvs[elem_index] := ?(key, val);

        let ?max = leaf_node.max else Debug.trap("1: insert (replace entry): should have a max value");
        let (max_key, max_val, max_index) = max;

        if (cmp_key(max_key, key) == #equal and cmp_val(val, max_val) == #less) {
            leaf_node.max := null;

            label _loop for (i in Iter.range(0, leaf_node.count - 1)) {
                // if (i == max_index) continue _loop;

                let ?(k, v) = leaf_node.kvs[i] else Debug.trap("insert (replace entry): accessed a null value");
                Common.update_leaf_fields(leaf_node, cmp_val, i, k, v);
            };
        } else {
            Common.update_leaf_fields(leaf_node, cmp_val, elem_index, key, val);
        };

        let ?_new_max = leaf_node.max else Debug.trap("2: insert (replace entry): should have a max value");
        var new_max = _new_max;
        var prev_child_index = leaf_node.index;

        func calc_max_val(branch : Branch<Nat, Nat>) : Bool {
            let (new_max_key, new_max_val, _) = new_max;

            let ?max = branch.max else Debug.trap("3: insert (replace entry): should have a max value");
            let branch_max_key = max.0;
            let branch_max_val = max.1;
            let max_index = max.2;

            // let should_continue = cmp_val(new_max_val, branch_max_val) == #greater;
            let is_greater = cmp_val(new_max_val, branch_max_val) == #greater;

            if (not is_greater) {
                new_max := (branch_max_key, branch_max_val, branch.index);
            } else {
                branch.max := ?(new_max_key, new_max_val, prev_child_index);
            };

            prev_child_index := branch.index;

            true;
        };

        func decrement_branch_and_calc_max_val(branch : Branch<Nat, Nat>) {
            if (not called_independently) {
                // revert the subtree size increase from the top level insert function
                branch.subtree_size -= 1;
            };
            ignore calc_max_val(branch);
        };

        // undoes the update to subtree count for the nodes on the path to the root when replacing a key-value pair
        Methods.update_branch_path_from_leaf_to_root(max_bp_tree, leaf_node, decrement_branch_and_calc_max_val);

        if (called_independently) {
            var child_index = leaf_node.index;
            func inc_branch_subtree_size(branch : Branch<Nat, Nat>) {
                // increase the subtree size of every branch on the path to the leaf node
                branch.subtree_size += 1;

                // update the max value of the branch node if necessary
                // note:    this function selects the max value by comparing all the max values in the children
                //          of the branch node. However, since the max value of the child node storing the key-value
                //          pair we are removing has not yet computed its new max value, the value stored here is just
                //          a placeholder (or best possible option) until the new max value is computed.
                let ?max = branch.max else Debug.trap("insert(inc_branch_subtree_size): should have a max value");
                let (max_key, max_val, max_index) = max;

                if (cmp_key(max_key, key) == #equal and cmp_val(val, max_val) == #less) {
                    branch.max := null;

                    label _loop for (i in Iter.range(0, branch.count - 1)) {

                        let ?child = branch.children[i] else Debug.trap("insert(inc_branch_subtree_size): accessed a null value");

                        if (i == max_index) {
                            let #branch(node) or #leaf(node) : CommonNodeFields<Nat, Nat> = child;
                            assert i == node.index;
                            let ?node_max = node.max else Debug.trap("insert(inc_branch_subtree_size): should have a max key");
                            assert cmp_key(node_max.1, max_val) == #equal;
                            continue _loop;
                        };

                        Common.update_branch_fields(branch, cmp_val, i, child);
                    };
                };

                child_index := branch.index;
            };

            Methods.update_branch_path_from_leaf_to_root<Nat, Nat>(max_bp_tree, leaf_node, inc_branch_subtree_size);
        };

        return ?kv.1;

    };

    public func _insert_at_leaf_index(max_bp_tree : MaxBpTree<Nat, Nat>, cmp_key : CmpFn<Nat>, cmp_val : CmpFn<Nat>, leaf_node : Leaf<Nat, Nat>, elem_index : Nat, key : Nat, val : Nat, called_independently : Bool) : ?Nat {
        
        let entry = (key, val);

        let prev_value = null;

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

            Common.update_leaf_fields(leaf_node, cmp_val, elem_index, key, val);
            return prev_value;
        };

        func gen_id() : Nat = Methods.gen_id(max_bp_tree);

        // split leaf node
        let right_leaf_node = Leaf.split<Nat, Nat>(leaf_node, elem_index, entry, gen_id, cmp_key, cmp_val);

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

            if (called_independently) parent.subtree_size += 1;

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
                        case ((? #branch(node) or ? #leaf(node)) : ?CommonNodeFields<Nat, Nat>) {
                            node.index := j;

                            if (j == right_index) {
                                let ?parent_max = parent.max else Debug.trap("3. insert: accessed a null value");
                                let (parent_max_key, parent_max_val, parent_max_index) = parent_max;

                                let ?node_max = node.max else Debug.trap("3. insert: accessed a null value");
                                let (node_max_key, node_max_val, node_max_index) = node_max;

                                let cmp_result = cmp_val(node_max_val, parent_max_val);
                                if (cmp_result == #greater or (cmp_result == #equal and cmp_key(node_max_key, parent_max_key) == #equal)) {
                                    parent.max := ?(node_max_key, node_max_val, j);
                                } else if (parent_max_index >= right_index) {
                                    parent.max := ?(parent_max_key, parent_max_val, parent_max_index + 1);
                                };
                            };
                        };
                        case (_) {};
                    };

                    j -= 1;
                };

                parent.count += 1;

                max_bp_tree.size += 1;

                if (called_independently) {
                    label inc_loop switch (parent.parent) {
                        case (?parent) parent.subtree_size += 1;
                        case (null) break inc_loop;
                    };
                };

                return prev_value;

            } else {

                let median = (parent.count / 2) + 1; // include inserted key-value pair
                let prev_subtree_size = parent.subtree_size;

                let split_node = Branch.split(parent, right_node, right_index, right_key, gen_id, cmp_key, cmp_val);

                let ?first_key = Methods.extract(split_node.keys, split_node.keys.size() - 1 : Nat) else Debug.trap("4. insert: accessed a null value in first key of branch");
                right_key := first_key;

                left_node := #branch(parent);
                right_node := #branch(split_node);

                right_index := split_node.index;
                opt_parent := split_node.parent;

                subtree_diff := prev_subtree_size - parent.subtree_size;
            };
        };

        let root_node = Branch.new<Nat, Nat>(max_bp_tree.order, null, null, gen_id, cmp_val);
        root_node.keys[0] := ?right_key;
        
        Branch.add_child(root_node, cmp_val, left_node);
        Branch.add_child(root_node, cmp_val, right_node);

        max_bp_tree.root := #branch(root_node);
        max_bp_tree.size += 1;

        prev_value;
    };

    public func toLeafNodes<K, V>(self : MaxBpTree<K, V>) : [(?(K, V, Nat), [?(K, V)])] {
        var node = ?self.root;
        let buffer = Buffer.Buffer<(?(K, V, Nat), [?(K, V)])>(self.size);

        var leaf_node : ?Leaf<K, V> = ?Methods.get_min_leaf_node(self);

        label _loop loop {
            switch (leaf_node) {
                case (?leaf) {
                    buffer.add((leaf.max, Array.freeze<?(K, V)>(leaf.kvs)));
                    leaf_node := leaf.next;
                };
                case (_) break _loop;
            };
        };

        Buffer.toArray(buffer);
    };

    public func toNodeKeys<K, V>(self : MaxBpTree<K, V>) : [[(Nat, ?(K, V, Nat), [?K])]] {
        var nodes = BufferDeque.fromArray<?Node<K, V>>([?self.root]);
        let buffer = Buffer.Buffer<[(Nat, ?(K, V, Nat), [?K])]>(self.size / 2);

        while (nodes.size() > 0) {
            let row = Buffer.Buffer<(Nat, ?(K, V, Nat), [?K])>(nodes.size());

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

                        row.add((node.index, node.max, Buffer.toArray(node_buffer)));
                    };
                    case (_) {};
                };
            };

            buffer.add(Buffer.toArray(row));
        };

        Buffer.toArray(buffer);
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
    public func remove(self : MaxBpTree<Nat, Nat>, cmp_key : CmpFn<Nat>, cmp_val : CmpFn<Nat>, key : Nat) : ?Nat {
        if (self.size == 0) return null;

        func update_path_downstream(branch : Branch<Nat, Nat>, child_index : Nat) {
            // reduce the subtree size of every branch on the path to the leaf node
            branch.subtree_size -= 1;

            // update the max value of the branch node if necessary
            let ?max = branch.max else Debug.trap("insert(update_path_downstream): should have a max value");
            let (max_key, max_val, max_index) = max;

            if (cmp_key(max_key, key) != #equal) return;

            branch.max := null;

            label _loop for (i in Iter.range(0, branch.count - 1)) {

                let ?child = branch.children[i] else Debug.trap("insert(update_path_downstream): accessed a null value");

                if (i == max_index) {
                    let #branch(node) or #leaf(node) : CommonNodeFields<Nat, Nat> = child;
                    assert i == node.index;
                    let ?node_max = node.max else Debug.trap("insert(update_path_downstream): should have a max key");
                    assert cmp_key(node_max.1, max_val) == #equal;
                    continue _loop;
                };

                Common.update_branch_fields(branch, cmp_val, i, child);
            };
        };

        let leaf_node = Methods.get_leaf_node_and_update_branch_path(self, cmp_key, key, update_path_downstream);

        let int_elem_index = ArrayMut.binary_search(leaf_node.kvs, Utils.adapt_cmp(cmp_key), key, leaf_node.count);

        let elem_index = if (int_elem_index >= 0) Int.abs(int_elem_index) else {
            func inc_branch_subtree_size(branch : Branch<Nat, Nat>) {
                branch.subtree_size += 1;
            };

            Methods.update_branch_path_from_leaf_to_root(self, leaf_node, inc_branch_subtree_size);

            return null;
        };

        _remove_from_leaf(self, cmp_key, cmp_val, leaf_node, elem_index, false);
    };

    public func _remove_from_leaf(self : MaxBpTree<Nat, Nat>, cmp_key : CmpFn<Nat>, cmp_val : CmpFn<Nat>, leaf_node : Leaf<Nat, Nat>, elem_index : Nat, called_independently : Bool) : ?Nat {

        // remove parent key
        let ?entry = ArrayMut.remove(leaf_node.kvs, elem_index, leaf_node.count) else Debug.trap("1. remove: accessed a null value");

        let key = entry.0;
        let deleted = entry.1;
        self.size -= 1;
        leaf_node.count -= 1;

        let ?leaf_max = leaf_node.max else Debug.trap("remove: should have a max value");
        let max_key = leaf_max.0;

        if (cmp_key(max_key, key) == #equal) {
            leaf_node.max := null;

            for (i in Iter.range(0, leaf_node.count - 1)) {
                let ?kv = leaf_node.kvs[i] else Debug.trap("2. remove: accessed a null value");
                Common.update_leaf_fields(leaf_node, cmp_val, i, kv.0, kv.1);
            };
        };

        if (self.size == 0) return ?deleted;

        let ?_new_max = leaf_node.max else Debug.trap("4: insert (replace entry): should have a max value");
        var new_max = _new_max;
        var prev_child_index = leaf_node.index;

        func update_path_upstream(branch : Branch<Nat, Nat>) : Bool {

            if (called_independently) {
                // reduce the subtree size of every branch on the path to the leaf node
                branch.subtree_size -= 1;

                // update the max value of the branch node if necessary
                let ?max = branch.max else Debug.trap("insert(update_path_downstream): should have a max value");
                let (max_key, max_val, max_index) = max;

                if (cmp_key(max_key, key) != #equal) return true;

                branch.max := null;

                label _loop for (i in Iter.range(0, branch.count - 1)) {

                    let ?child = branch.children[i] else Debug.trap("insert(update_path_downstream): accessed a null value");
                    Common.update_branch_fields(branch, cmp_val, i, child);
                };

                return true;
            };
            
            let (new_max_key, new_max_val, new_index) = new_max;

            let ?max = branch.max else Debug.trap("5: insert (replace entry): should have a max value");
            let (branch_max_key, branch_max_val, max_index) = max;

            let is_greater = cmp_val(new_max_val, branch_max_val) == #greater;

            if (not is_greater) {
                new_max := (branch_max_key, branch_max_val, branch.index);
            } else {
                branch.max := ?(new_max_key, new_max_val, prev_child_index);
            };

            prev_child_index := branch.index;

            true;
        };

        Methods.update_partial_branch_path_from_leaf_to_root(self, leaf_node, update_path_upstream);

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

            parent.keys[i - 1] := ?next_key;
        };

        if (elem_index == 0) {
            let next = leaf_node.kvs[elem_index]; // same as entry index because we removed the entry from the array
            let ?next_key = do ? { next!.0 } else Debug.trap("update_deleted_median_key: accessed a null value");
            update_deleted_median_key(parent, leaf_node.index, key, next_key);
        };

        if (leaf_node.count >= min_count) return ?deleted;

        Leaf.redistribute_keys(leaf_node, cmp_key, cmp_val);

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

        Leaf.merge(left_node, right_node, cmp_key, cmp_val);

        var branch_node = parent;
        let ?__parent = branch_node.parent else {

            // update root node as this node does not have a parent
            // which means it is the root node
            if (branch_node.count == 1) {
                let ?child = branch_node.children[0] else Debug.trap("3. remove: accessed a null value");
                switch (child) {
                    case (#branch(node) or #leaf(node) : CommonNodeFields<Nat, Nat>) {
                        node.parent := null;
                    };
                };
                self.root := child;
            };

            return ?deleted;
        };

        parent := __parent;

        while (branch_node.count < min_count) {
            Branch.redistribute_keys(branch_node, cmp_key, cmp_val);
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

            // Debug.print("parent before merge: " # debug_show Branch.toText(parent, Nat.toText, Nat.toText));
            Branch.merge(left_node, right_node, cmp_key, cmp_val);
            // Debug.print("parent after merge: " # debug_show Branch.toText(parent, Nat.toText, Nat.toText));

            branch_node := parent;
            let ?_parent = branch_node.parent else {
                // update root node if necessary
                if (branch_node.count == 1) {
                    let ?child = branch_node.children[0] else Debug.trap("3. remove: accessed a null value");
                    switch (child) {
                        case (#branch(node) or #leaf(node) : CommonNodeFields<Nat, Nat>) {
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
    ///     let max_bp_tree = Methods.fromEntries<Char, Nat>(null, entries, Char.compare);
    /// ```

    public func fromEntries(order : ?Nat, entries : Iter<(Nat, Nat)>, cmp_key : CmpFn<Nat>, cmp_val : CmpFn<Nat>) : MaxBpTree<Nat, Nat> {
        let max_bp_tree = MaxBpTree.new<Nat, Nat>(order);

        for ((k, v) in entries) {
            ignore insert(max_bp_tree, cmp_key, cmp_val, k, v);
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
    // public func fromArray<K, V>(order : ?Nat, arr : [(K, V)], cmp_key : CmpFn<K>, cmp_val: CmpFn<V>) : MaxBpTree<K, V> {
    //     let max_bp_tree = MaxBpTree.new<K, V>(order);

    //     for (kv in arr.vals()) {
    //         let (k, v) = kv;
    //         ignore MaxBpTree.insert(max_bp_tree, cmp_key, cmp_val, k, v);
    //     };

    //     max_bp_tree;
    // };

    /// Returns a sorted array of the key-value pairs in the tree.
    ///
    /// #### Examples
    /// ```motoko
    ///     let arr = [('A', 1), ('B', 2), ('C', 3)];
    ///     let max_bp_tree = MaxBpTree.fromArray<Char, Nat>(null, arr, Char.compare, Nat.compare);
    ///     assert MaxBpTree.toArray(max_bp_tree) == arr;
    /// ```
    public func toArray<K, V>(self : MaxBpTree<K, V>) : [(K, V)] {
        Methods.to_array<K, V>(self);
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
        switch (self.root) {
            case (#leaf(node) or #branch(node) : CommonNodeFields<K, V>) {
                let ?max = node.max else return null;

                ?(max.0, max.1);
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
        Methods.min(self);
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
        Methods.max(self);
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
    public func removeMin(self : MaxBpTree<Nat, Nat>, cmp_key : CmpFn<Nat>, cmp_val : CmpFn<Nat>) : ?(Nat, Nat) {
        let ?(min_key, _) = Methods.min(self) else return null;

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
    public func removeMax(self : MaxBpTree<Nat, Nat>, cmp_key : CmpFn<Nat>, cmp_val : CmpFn<Nat>) : ?(Nat, Nat) {
        let ?(max_key, _) = Methods.max(self) else return null;

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
    public func removeMaxValue(self : MaxBpTree<Nat, Nat>, cmp_key : CmpFn<Nat>, cmp_val : CmpFn<Nat>) : ?(Nat, Nat) {
        let ?(max_key, _) = MaxBpTree.maxValue(self) else return null;

        let ?v = remove(self, cmp_key, cmp_val, max_key) else return null;

        return ?(max_key, v);
    };

    /// Returns a double ended iterator over the entries of the tree.
    public func entries<K, V>(max_bp_tree : MaxBpTree<K, V>) : DoubleEndedIter<(K, V)> {
        Methods.entries(max_bp_tree);
    };

    /// Returns a double ended iterator over the keys of the tree.
    public func keys<K, V>(self : MaxBpTree<K, V>) : DoubleEndedIter<K> {
        Methods.keys(self);
    };

    /// Returns a double ended iterator over the values of the tree.
    public func vals<K, V>(self : MaxBpTree<K, V>) : DoubleEndedIter<V> {
        Methods.vals(self);
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
    ///     assert MaxBpTree.getIndex(max_bp_tree, Char.compare, 'B') == 1;
    ///     assert MaxBpTree.getIndex(max_bp_tree, Char.compare, 'D') == 3;
    /// ```
    public func getIndex<K, V>(self : MaxBpTree<K, V>, cmp : CmpFn<K>, key : K) : Nat {
        Methods.get_index(self, cmp, key);
    };

    /// Returns the key-value pair at the given rank.
    /// Returns null if the rank is greater than the size of the tree.
    ///
    /// #### Examples
    /// ```motoko
    ///     let arr = [('A', 1), ('B', 2), ('C', 3)];
    ///     let max_bp_tree = MaxBpTree.fromArray<Char, Nat>(null, arr, Char.compare, Nat.compare);
    ///
    ///     assert MaxBpTree.getFromIndex(max_bp_tree, 0) == ('A', 1);
    ///     assert MaxBpTree.getFromIndex(max_bp_tree, 1) == ('B', 2);
    /// ```
    public func getFromIndex<K, V>(self : MaxBpTree<K, V>, rank : Nat) : (K, V) {
        Methods.get_from_index(self, rank);
    };

    /// Returns an iterator over the entries of the tree in the range [start, end].
    /// The range is defined by the ranks of the start and end keys
    public func range<K, V>(self : MaxBpTree<K, V>, start : Nat, end : Nat) : DoubleEndedIter<(K, V)> {
        Methods.range(self, start, end);
    };

    /// Returns an iterator over the entries of the tree in the range [start, end].
    /// The iterator is inclusive of start and end.
    ///
    /// If the start key does not exist in the tree then the iterator will start from next key greater than start.
    /// If the end key does not exist in the tree then the iterator will end at the last key less than end.
    public func scan<K, V>(self : MaxBpTree<K, V>, cmp : CmpFn<K>, start : K, end : K) : DoubleEndedIter<(K, V)> {
        Methods.scan(self, cmp, start, end);
    };

};
