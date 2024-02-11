import Iter "mo:base/Iter";
import Debug "mo:base/Debug";
import Array "mo:base/Array";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Order "mo:base/Order";
import Option "mo:base/Option";

import T "Types";
import InternalTypes "../internal/Types";
import Leaf "Leaf";
import Utils "../internal/Utils";
import ArrayMut "../internal/ArrayMut";

import Common "Common";

module Branch {
    type Order = Order.Order;
    public type Branch<K, V> = T.Branch<K, V>;
    type Node<K, V> = T.Node<K, V>;
    type Leaf<K, V> = T.Leaf<K, V>;
    type CmpFn<K> = InternalTypes.CmpFn<K>;
    type CommonNodeFields<K, V> = T.CommonNodeFields<K, V>;
    type MaxBpTree<K, V> = T.MaxBpTree<K, V>;
    type UpdateBranchMaxFn<K, V> = T.UpdateBranchMaxFn<K, V>;
    type ResetMaxFn<K, V> = T.ResetMaxFn<K, V>;

    public func new<K, V>(
        order : Nat,
        opt_keys : ?[var ?K],
        opt_children : ?[var ?Node<K, V>],
        gen_id : () -> Nat,
        cmp_val : CmpFn<V>,
    ) : Branch<K, V> {

        let self : Branch<K, V> = {
            id = gen_id();
            var parent = null;
            var index = 0;
            var keys = [var];
            var children = [var];
            var count = 0;
            var subtree_size = 0;
            var max = null;
        };

        let children = switch (opt_children) {
            case (?children) { children };
            case (_) {
                self.keys := Array.init<?K>(order - 1, null);
                self.children := Array.init<?Node<K, V>>(order, null);
                return self;
            };
        };

        switch (children[0]) {
            case (? #leaf(node)) {
                node.parent := ?self;
                node.index := 0;
                self.count += 1;
                self.subtree_size += node.count;

                Common.update_branch_fields(self, cmp_val, 0, #leaf(node));
            };
            case (? #branch(node)) {
                node.parent := ?self;
                node.index := 0;
                self.count += 1;
                self.subtree_size += node.subtree_size;

                Common.update_branch_fields(self, cmp_val, 0, #branch(node));
            };
            case (_) Debug.trap("Branch.new: should replace the opt_children input with a null value ");
        };

        let keys = switch (opt_keys) {
            case (?keys) {
                label _loop for (i in Iter.range(1, children.size() - 1)) {
                    switch (children[i]) {
                        case (? #leaf(node)) {
                            node.parent := ?self;
                            node.index := self.count;
                            self.count += 1;
                            self.subtree_size += node.count;

                            Common.update_branch_fields(self, cmp_val, node.index, #leaf(node));
                        };
                        case (? #branch(node)) {
                            node.parent := ?self;
                            node.index := self.count;
                            self.count += 1;
                            self.subtree_size += node.subtree_size;

                            Common.update_branch_fields(self, cmp_val, node.index, #branch(node));

                        };
                        case (_) { break _loop };
                    };
                };
                keys;
            };
            case (_) {
                Utils.tabulate_var<K>(
                    order - 1 : Nat,
                    order - 1,
                    func(i : Nat) : ?K {
                        let child_index = i + 1;
                        switch (children[child_index]) {
                            case (? #leaf(node)) {
                                node.parent := ?self;
                                node.index := self.count;
                                self.count += 1;
                                self.subtree_size += node.count;

                                Common.update_branch_fields(self, cmp_val, child_index, #leaf(node));

                                switch (node.kvs[0]) {
                                    case (?kv) ?kv.0;
                                    case (_) null;
                                };
                            };
                            case (? #branch(node)) {
                                node.parent := ?self;
                                node.index := self.count;
                                self.count += 1;
                                self.subtree_size += node.subtree_size;

                                Common.update_branch_fields(self, cmp_val, child_index, #branch(node));

                                node.keys[0];
                            };
                            case (_) null;
                        };
                    },
                );
            };
        };

        self.keys := keys;
        self.children := children;

        self;
    };

    public func update_median_key<K, V>(_parent : Branch<K, V>, index : Nat, new_key : K) {
        var parent = _parent;
        var i = index;

        while (i == 0) {
            i := parent.index;
            let ?__parent = parent.parent else return; // occurs when key is the first key in the tree
            parent := __parent;
        };

        parent.keys[i - 1] := ?new_key;
    };

    public func split<K, V>(
        node : Branch<K, V>,
        child : Node<K, V>,
        child_index : Nat,
        first_child_key : K,
        gen_id : () -> Nat,
        cmp_key : CmpFn<K>,
        cmp_val : CmpFn<V>,
    ) : Branch<K, V> {

        let arr_len = node.count;
        let median = (arr_len / 2) + 1;

        let is_elem_added_to_right = child_index >= median;

        var median_key = ?first_child_key;

        var offset = if (is_elem_added_to_right) 0 else 1;
        var already_inserted = false;

        let right_keys = Array.init<?K>(node.keys.size(), null);

        let right_children = Utils.tabulate_var<Node<K, V>>(
            node.children.size(),
            node.count + 1 - median,
            func(i : Nat) : ?Node<K, V> {

                let j = i + median - offset : Nat;

                let child_node = if (j >= median and j == child_index and not already_inserted) {
                    offset += 1;
                    already_inserted := true;
                    if (i > 0) right_keys[i - 1] := ?first_child_key;
                    ?child;
                } else if (j >= arr_len) {
                    null;
                } else {
                    if (i == 0) {
                        median_key := node.keys[j - 1];
                    } else {
                        right_keys[i - 1] := node.keys[j - 1];
                    };
                    node.keys[j - 1] := null;
                    Utils.extract(node.children, j);
                };

                switch (child_node) {
                    case (? #branch(child)) {
                        child.index := i;
                        node.subtree_size -= child.subtree_size;
                    };
                    case (? #leaf(child)) {
                        child.index := i;
                        node.subtree_size -= child.count;
                    };
                    case (_) {};
                };

                child_node;
            },
        );

        var j = median - 1 : Nat;

        while (j > child_index) {
            if (j >= 2) {
                node.keys[j - 1] := node.keys[j - 2];
            };

            node.children[j] := node.children[j - 1];

            switch (node.children[j]) {
                case (? #branch(node) or ? #leaf(node) : ?CommonNodeFields<K, V>) {
                    node.index := j;
                };
                case (_) {};
            };

            j -= 1;
        };

        if (j == child_index) {
            if (j > 0) {
                node.keys[j - 1] := ?first_child_key;
                node.children[j] := ?child;
            } else {
                update_median_key(node, 0, first_child_key);
                node.children[0] := ?child;
            };
        };

        node.count := median;
        let right_cnt = node.children.size() + 1 - median : Nat;

        let right_node : Branch<K, V> = switch (node.children[0]) {
            case (? #leaf(_)) Branch.new<K, V>(node.children.size(), null, ?right_children, gen_id, cmp_val);
            case (? #branch(_)) {
                Branch.new(node.children.size(), ?right_keys, ?right_children, gen_id, cmp_val);
                // Branch new fails to update the median key to its correct position so we do it manually
            };
            case (_) Debug.trap("right_node: accessed a null value");
        };

        right_node.index := node.index + 1;

        right_node.count := right_cnt;
        right_node.parent := node.parent;

        // store the first key of the right node at the end of the keys in left node
        // no need to delete as the value will get overwritten because it exceeds the count position
        right_node.keys[right_node.keys.size() - 1] := median_key;

        // update the left node's extra fields

        var i = 0;
        node.max := null;
        while (i < node.count) {
            let ?child = node.children[i] else Debug.trap("Leaf.split: child is null");
            Common.update_branch_fields(node, cmp_val, i, child);
            i += 1;
        };

        right_node;
    };

    public func shift_by<K, V>(branch : Branch<K, V>, start : Nat, end : Nat, offset : Int) {
        if (offset == 0) return;

        if (offset > 0) {
            var i = end; // exclusive

            while (i > start) {
                let child = branch.children[i - 1];
                branch.children[i - 1] := null;

                let j = Int.abs(offset) + i - 1 : Nat;
                branch.children[j] := child;

                switch (child) {
                    case (? #branch(node) or ? #leaf(node) : ?CommonNodeFields<K, V>) {
                        node.index := j;
                    };
                    case (_) {};
                };

                i -= 1;
            };
        } else {
            var i = start;
            while (i < end) {
                let child = branch.children[i];
                branch.children[i] := null;

                let j = Int.abs(i + offset);
                branch.children[j] := child;

                switch (child) {
                    case (? #branch(node) or ? #leaf(node) : ?CommonNodeFields<K, V>) {
                        node.index := j;
                    };
                    case (_) {};
                };

                i += 1;
            };
        };

        switch (branch.max) {
            case (?max) branch.max := ?(max.0, max.1, Int.abs(max.2 + offset));
            case (_) {};
        };
    };

    public func put<K, V>(branch : Branch<K, V>, i : Nat, child : Node<K, V>) {
        branch.children[i] := ?child;

        switch (child) {
            case (#branch(node) or #leaf(node) : CommonNodeFields<K, V>) {
                node.parent := ?branch;
                node.index := i;
            };
        };
    };

    public func insert<K, V>(branch : Branch<K, V>, i : Nat, child : Node<K, V>) {

        var j = i;

        while (j < branch.count) {
            branch.children[j + 1] := branch.children[j];

            switch (branch.children[j + 1]) {
                case (? #branch(node) or ? #leaf(node) : ?CommonNodeFields<K, V>) {
                    node.parent := ?branch;
                    node.index := j + 1;
                };
                case (_) {};
            };
            j += 1;
        };

        branch.children[i] := ?child;

        switch (child) {
            case (#branch(node) or #leaf(node) : CommonNodeFields<K, V>) {
                node.parent := ?branch;
                node.index := i;
            };
        };

    };

    public func remove<K, V>(
        self : Branch<K, V>,
        index : Nat,
        count : Nat,
        cmp_val : CmpFn<V>,
    ) : ?Node<K, V> {
        let removed = self.children[index];
        
        var i = index;
        while (i < (count - 1 : Nat)) {
            self.children[i] := self.children[i + 1];

            let ?child = self.children[i] else Debug.trap("Branch.remove: accessed a null value");

            switch (child) {
                case (#leaf(node) or #branch(node) : CommonNodeFields<K, V>) {
                    node.index := i;
                };
            };

            // update with the prev index as it will be updated after the loop
            Common.update_branch_fields(self, cmp_val, i + 1, child);

            i += 1;
        };

        // update the max field index
        switch(self.max){
            case (?max) {
                if (max.2 > index) {
                    self.max := ?(max.0, max.1, max.2 - 1);
                }
            };
            case (null) {
                // only allowed when the last element is removed
                if (self.count != 1){
                    // Debug.print("branch: ")
                    Debug.trap("Branch max is null and the count is " # debug_show self.count);
                };
            } 
        };

        self.children[count - 1] := null;
        // self.count -=1;

        removed;
    };

    public func redistribute_keys<K, V>(
        branch_node : Branch<K, V>,
        cmp_key : CmpFn<K>,
        cmp_val : CmpFn<V>,
    ) {

        // every node from this point on has a parent because an adjacent node was found
        let ?parent = branch_node.parent else return;
        
        // retrieve adjacent node
        var adj_node = branch_node;
        if (parent.count > 1) {
            if (branch_node.index != 0) {
                let ? #branch(left_adj_node) = parent.children[branch_node.index - 1] else Debug.trap("1. redistribute_branch_keys: accessed a null value");
                adj_node := left_adj_node;
            };

            if (branch_node.index + 1 != parent.count) {
                let ? #branch(right_adj_node) = parent.children[branch_node.index + 1] else Debug.trap("2. redistribute_branch_keys: accessed a null value");
                if (right_adj_node.count > adj_node.count) {
                    adj_node := right_adj_node;
                };
            };
        };

        if (adj_node.index == branch_node.index) return; // no adjacent node to distribute data to

        let sum_count = branch_node.count + adj_node.count;
        let min_count_for_both_nodes = branch_node.children.size();

        if (sum_count < min_count_for_both_nodes) return; // not enough entries to distribute

        let data_to_move = (sum_count / 2) - branch_node.count : Nat;

        var moved_subtree_size = 0;

        let is_adj_node_equal_to_parent_max = switch (parent.max, adj_node.max) {
            case (?parent_max, ?adj_max) cmp_key(parent_max.0, adj_max.0) == #equal;
            case (_, _) false;
        };

        // distribute data between adjacent nodes
        if (adj_node.index < branch_node.index) {
            // adj_node is before branch_node
            var median_key = parent.keys[adj_node.index];

            ArrayMut.shift_by(branch_node.keys, 0, branch_node.count - 1 : Nat, data_to_move : Nat);
            Branch.shift_by(branch_node, 0, branch_node.count : Nat, data_to_move : Nat);
            var i = 0;
            for (_ in Iter.range(0, data_to_move - 1)) {
                let j = adj_node.count - i - 1 : Nat;
                branch_node.keys[data_to_move - i - 1] := median_key;
                let ?mk = ArrayMut.remove(adj_node.keys, j - 1 : Nat, adj_node.count - 1 : Nat) else Debug.trap("4. redistribute_branch_keys: accessed a null value");
                median_key := ?mk;

                let new_node_index = data_to_move - i - 1 : Nat;
                let ?val = Utils.extract(adj_node.children, j) else Debug.trap("4. redistribute_branch_keys: accessed a null value");
                
                let #leaf(new_child_node) or #branch(new_child_node) : CommonNodeFields<K, V> = val;

                // remove the adj_node max if it was removed
                switch(adj_node.max) {
                    case (?adj_max)  if (adj_max.2 <= j) adj_node.max := null;
                    case (_) {};
                };

                // no need to call update_fields as we are the adjacent node is before the leaf node
                // which means that all its keys are less than the leaf node's keys
                Branch.put(branch_node, new_node_index, val);

                // update the branch node max if the inserted value's max is greater than the current max
                switch(branch_node.max, new_child_node.max){
                    case (?branch_max, ?child_max) {
                        if (cmp_val(child_max.1, branch_max.1) == #greater) {
                            branch_node.max := ?(child_max.0, child_max.1, new_node_index);
                        };
                    };
                    case (_) Debug.trap("Branch.redistribute_keys: branch max is null");
                };

                // update the subtree size
                switch (val) {
                    case (#branch(node)) {
                        moved_subtree_size += node.subtree_size;
                    };
                    case (#leaf(node)) {
                        moved_subtree_size += node.count;
                    };
                };

                i += 1;
            };

            parent.keys[adj_node.index] := median_key;

        } else {
            // adj_node is after branch_node
            var j = branch_node.count : Nat;
            var median_key = parent.keys[branch_node.index];
            var i = 0;

            for (_ in Iter.range(0, data_to_move - 1)) {
                ArrayMut.insert(branch_node.keys, branch_node.count + i - 1 : Nat, median_key, branch_node.count - 1 : Nat);
                median_key := adj_node.keys[i];

                let ?val = adj_node.children[i] else Debug.trap("5. redistribute_branch_keys: accessed a null value");
                Branch.insert(branch_node, branch_node.count + i, val);

                // remove the adj_node max if it was removed
                switch(adj_node.max) {
                    case (?adj_max)  if (adj_max.2 <= i) adj_node.max := null;
                    case (_) {};
                };

                let #branch(child_node) or #leaf(child_node) : CommonNodeFields<K, V> = val;

                // update the branch node max if the inserted value's max is greater than the current max
                switch(branch_node.max, child_node.max){
                    case (?branch_max, ?child_max) {
                        if (cmp_val(child_max.1, branch_max.1) == #greater) {
                            branch_node.max := ?(child_max.0, child_max.1, branch_node.count + i);
                        };
                    };
                    case (_) Debug.trap("Branch.redistribute_keys: branch max is null");
                };

                // update subtree size
                switch (val) {
                    case (#branch(node)) {
                        moved_subtree_size += node.subtree_size;
                    };
                    case (#leaf(node)) {
                        moved_subtree_size += node.count;
                    };
                };

                i += 1;
            };

            ArrayMut.shift_by(adj_node.keys, i, adj_node.count - 1 : Nat, -data_to_move : Int);
            Branch.shift_by(adj_node, i, adj_node.count : Nat, -data_to_move : Int);

            parent.keys[branch_node.index] := median_key;

        };

        adj_node.count -= data_to_move;
        branch_node.count += data_to_move;

        adj_node.subtree_size -= moved_subtree_size;
        branch_node.subtree_size += moved_subtree_size;

        if (Option.isNull(adj_node.max)){

            var i = 0;
            while (i < adj_node.count) {
                let ?node = adj_node.children[i] else Debug.trap("Leaf.redistribute_keys: kv is null");
                Common.update_branch_fields(adj_node, cmp_val, i, node);
                i += 1;
            };
        };

        // update parent max
        if (is_adj_node_equal_to_parent_max) {
            switch(parent.max, adj_node.max) {
                case (?parent_max, ?adj_max) {
                    if (cmp_key(parent_max.0, adj_max.0) != #equal) {
                        parent.max := ?(parent_max.0, parent_max.1, branch_node.index);
                    };
                };
                case (_, _) {};
            };
        };
    };

    public func merge<K, V>(
        left : Branch<K, V>,
        right : Branch<K, V>,
        cmp_key : CmpFn<K>,
        cmp_val : CmpFn<V>,
    ) {
        // assert left.index + 1 == right.index;

        // if there are two adjacent nodes then there must be a parent
        let ?parent = left.parent else Debug.trap("1. merge_branch_nodes: accessed a null value");

        var median_key = parent.keys[right.index - 1];
        let right_subtree_size = right.subtree_size;
        // merge right into left
        for (i in Iter.range(0, right.count - 1)) {
            ArrayMut.insert(left.keys, left.count + i - 1 : Nat, median_key, left.count - 1 : Nat);
            median_key := right.keys[i];

            let ?child = right.children[i] else Debug.trap("2. merge_branch_nodes: accessed a null value");
            Branch.insert(left, left.count + i, child);

            Common.update_branch_fields(left, cmp_val, left.count + i, child);

        };

        left.count += right.count;
        left.subtree_size += right_subtree_size;

        // update the parent fields with the updated left node
        let ?parent_max = parent.max else Debug.trap("3. merge_branch_nodes: accessed a null value");
        let ?right_max = right.max else Debug.trap("4. merge_branch_nodes: accessed a null value");

        if (parent_max.2 == right.index) {
            parent.max := ?(parent_max.0, parent_max.1, left.index);
        };

        // update parent keys
        ignore ArrayMut.remove(parent.keys, right.index - 1 : Nat, parent.count - 1 : Nat);
        ignore Branch.remove(parent, right.index, parent.count, cmp_val);
        parent.count -= 1;

    };

    public func toText<K, V>(self : Branch<K, V>, key_to_text : (K) -> Text, val_to_text : (V) -> Text) : Text {
        var t = "branch { index: " # debug_show self.index # ", count: " # debug_show self.count # ", subtree: " # debug_show self.subtree_size # ", keys: ";
        t #= debug_show Array.map(
            Array.freeze(self.keys),
            func(opt_key : ?K) : Text {
                switch (opt_key) {
                    case (?key) key_to_text(key);
                    case (_) "null";
                };
            },
        );

        t #= ", children: " # debug_show Array.map(
            Array.freeze(self.children),
            func(opt_node : ?Node<K, V>) : Text {
                switch (opt_node) {
                    case (? #leaf(node)) Leaf.toText<K, V>(node, key_to_text, val_to_text);
                    case (? #branch(node)) Branch.toText(node, key_to_text, val_to_text);
                    case (_) "null";
                };
            },
        );

        t #= " }";

        t;
    };

};
