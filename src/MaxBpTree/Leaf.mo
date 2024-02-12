import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Int "mo:base/Int";

import BpTreeLeaf "../BpTree/Leaf";
import T "Types";
import BpTree "../BpTree";
import ArrayMut "../internal/ArrayMut";

import Utils "../internal/Utils";
import InternalTypes "../internal/Types";
import Common "Common";

module Leaf {
    type Iter<A> = Iter.Iter<A>;

    public type MaxBpTree<K, V> = T.MaxBpTree<K, V>;
    public type Node<K, V> = T.Node<K, V>;
    public type Leaf<K, V> = T.Leaf<K, V>;
    public type Branch<K, V> = T.Branch<K, V>;
    type CommonFields<K, V> = T.CommonFields<K, V>;
    type CommonNodeFields<K, V> = T.CommonNodeFields<K, V>;
    type MultiCmpFn<A, B> = InternalTypes.MultiCmpFn<A, B>;
    type CmpFn<A> = InternalTypes.CmpFn<A>;
    type UpdateLeafMaxFn<K, V> = T.UpdateLeafMaxFn<K, V>;
    type UpdateBranchMaxFn<K, V> = T.UpdateBranchMaxFn<K, V>;
    type ResetMaxFn<K, V> = T.ResetMaxFn<K, V>;

    public func new<K, V>(order : Nat, count : Nat, opt_kvs : ?[var ?(K, V)], gen_id : () -> Nat, cmp_val : CmpFn<V>) : Leaf<K, V> {

        let leaf_node : Leaf<K, V> = {
            id = gen_id();
            var parent = null;
            var index = 0;
            kvs = switch (opt_kvs) {
                case (?kvs) kvs;
                case (_) Array.init<?(K, V)>(order, null);
            };
            var count = count;
            var next = null;
            var prev = null;
            var max = null;
        };

        var i = 0;

        while (i < count) {
            let ?kv = leaf_node.kvs[i] else Debug.trap("Leaf.new: kv is null");
            Common.update_leaf_fields(leaf_node, cmp_val, i, kv.0, kv.1);
            i += 1;
        };

        leaf_node;
    };

    public func split<K, V>(
        leaf : Leaf<K, V>,
        elem_index : Nat,
        elem : (K, V),
        gen_id : () -> Nat,
        cmp_key : CmpFn<K>,
        cmp_val : CmpFn<V>,
    ) : Leaf<K, V> {

        let arr_len = leaf.count;
        let median = (arr_len / 2) + 1;

        let is_elem_added_to_right = elem_index >= median;

        // if elem is added to the left
        // this variable allows us to retrieve the last element on the left
        // that gets shifted by the inserted elemeent
        var offset = if (is_elem_added_to_right) 0 else 1;
        let right_cnt = arr_len + 1 - median : Nat;
        let right_node = Leaf.new<K, V>(leaf.kvs.size(), 0, null, gen_id, cmp_val);

        var already_inserted = false;

        var i = 0;
        while (i < right_cnt) {
            let j = i + median - offset : Nat;

            let ?kv = if (j >= median and j == elem_index and not already_inserted) {
                offset += 1;
                already_inserted := true;
                ?elem;
            } else {
                Utils.extract(leaf.kvs, j);
            } else Debug.trap("Leaf.split: kv is null");

            right_node.kvs[i] := ?kv;
            Common.update_leaf_fields(right_node, cmp_val, i, kv.0, kv.1);

            i += 1;
        };

        right_node.count := right_cnt;

        let moved_left_max = switch(leaf.max){
            case (?max){
                if (max.2 >= 0){
                    leaf.max := null;
                    true;
                }
                // else if (max.2 >= elem_index){
                //     leaf.max := ?(max.0, max.1, max.2 + 1);
                //     false
                // } 
                else false;
            };
            case (_) Debug.trap("Leaf.split: max is null");
        };

        var j = median - 1 : Nat;

        label while_loop while (moved_left_max or j >= elem_index) {
            if (j > elem_index) {
                leaf.kvs[j] := leaf.kvs[j - 1];
            } else if (j == elem_index) {
                leaf.kvs[j] := ?elem;
            };

            if (moved_left_max) {
                let ?kv = leaf.kvs[j] else Debug.trap("Leaf.split: kv is null");
                Common.update_leaf_fields(leaf, cmp_val, j, kv.0, kv.1);
            }else if (j == elem_index) {
                Common.update_leaf_fields(leaf, cmp_val, i, elem.0, elem.1);
            };

            if (j == 0) break while_loop else j -= 1;
        };

        leaf.count := median;

        right_node.index := leaf.index + 1;
        right_node.parent := leaf.parent;

        // update leaf pointers
        right_node.next := leaf.next;
        leaf.next := ?right_node;

        right_node.prev := ?leaf;

        switch (right_node.next) {
            case (?next) next.prev := ?right_node;
            case (_) {};
        };

        right_node;
    };

    public func shift_by<K, V>(
        leaf : Leaf<K, V>,
        start : Nat,
        end : Nat,
        offset : Int,
    ) {
        ArrayMut.shift_by(leaf.kvs, start, end, offset);
        switch (leaf.max) {
            case (?max) {
                leaf.max := ?(max.0, max.1, Int.abs(max.2 + offset));
            };
            case (_) {};
        };
    };

    public func put<K, V>(leaf : Leaf<K, V>, index : Nat, kv : (K, V)) {
        leaf.kvs[index] := ?kv;
    };

    public func redistribute_keys<K, V>(
        leaf_node : Leaf<K, V>,
        cmp_key : CmpFn<K>,
        cmp_val : CmpFn<V>,
    ) {

        let ?parent = leaf_node.parent else return;

        var adj_node = leaf_node;
        if (parent.count > 1) {
            if (leaf_node.index != 0) {
                let ? #leaf(left_adj_node) = parent.children[leaf_node.index - 1] else Debug.trap("1. redistribute_leaf_keys: accessed a null value");
                adj_node := left_adj_node;
            };

            if (leaf_node.index != (parent.count - 1 : Nat)) {
                let ? #leaf(right_adj_node) = parent.children[leaf_node.index + 1] else Debug.trap("2. redistribute_leaf_keys: accessed a null value");
                if (right_adj_node.count > adj_node.count) {
                    adj_node := right_adj_node;
                };
            };
        };

        if (adj_node.index == leaf_node.index) return; // no adjacent node to distribute data to

        let sum_count = leaf_node.count + adj_node.count;
        let min_count_for_both_nodes = leaf_node.kvs.size();

        if (sum_count < min_count_for_both_nodes) return; // not enough entries to distribute

        let data_to_move = (sum_count / 2) - leaf_node.count : Nat;

        let is_adj_node_equal_to_parent_max = switch (parent.max, adj_node.max) {
            case (?parent_max, ?adj_max) cmp_key(parent_max.0, adj_max.0) == #equal;
            case (_, _) false;
        };

        // distribute data between adjacent nodes
        if (adj_node.index < leaf_node.index) {
            // adj_node is before leaf_node

            var i = 0;
            Leaf.shift_by(leaf_node, 0, leaf_node.count, data_to_move);
            for (_ in Iter.range(0, data_to_move - 1)) {
                let opt_kv = ArrayMut.remove(adj_node.kvs, adj_node.count - i - 1 : Nat, adj_node.count);
                let ?kv = opt_kv else Debug.trap("Leaf.redistribute_keys: kv is null");

                // no need to call update_fields as the adjacent node is before the leaf node
                // which means that all its keys are less than the leaf node's keys
                leaf_node.kvs[data_to_move - i - 1] := opt_kv;

                // update max if a greater value was inserted
                let ?leaf_max = leaf_node.max else Debug.trap("Leaf.redistribute_keys: max is null");
                if (cmp_val(kv.1, leaf_max.1) == #greater) {
                    leaf_node.max := ?(kv.0, kv.1, data_to_move - i - 1);
                };

                // remove max from adj_node if it was moved
                switch(adj_node.max){
                    case (?adj_max) if (cmp_key(kv.0, adj_max.0) == #equal) adj_node.max := null;
                    case (_) {};
                };

                i += 1;
            };
        } else {
            // adj_node is after leaf_node

            var i = 0;
            for (_ in Iter.range(0, data_to_move - 1)) {
                let opt_kv = adj_node.kvs[i];
                ArrayMut.insert(leaf_node.kvs, leaf_node.count + i, opt_kv, leaf_node.count);

                let ?kv = opt_kv else Debug.trap("Leaf.redistribute_keys: kv is null");

                // update max if a greater value was inserted
                let ?leaf_max = leaf_node.max else Debug.trap("Leaf.redistribute_keys: max is null");
                if (cmp_val(kv.1, leaf_max.1) == #greater) {
                    leaf_node.max := ?(kv.0, kv.1, leaf_node.count + i);
                };

                // remove max from adj_node if it was moved
                switch(adj_node.max){
                    case (?adj_max) if (cmp_key(kv.0, adj_max.0) == #equal) adj_node.max := null;
                    case (_) {};
                };

                i += 1;
            };

            Leaf.shift_by(adj_node, i, adj_node.count, -i);
        };

        adj_node.count -= data_to_move;
        leaf_node.count += data_to_move;

        if (Option.isNull(adj_node.max)) {
            var i = 0;

            while (i < adj_node.count) {
                let ?kv = adj_node.kvs[i] else Debug.trap("Leaf.redistribute_keys: kv is null");
                Common.update_leaf_fields(adj_node, cmp_val, i, kv.0, kv.1);
                i += 1;
            };

        };

        // update parent keys
        if (adj_node.index < leaf_node.index) {
            // no need to worry about leaf_node.index - 1 being out of bounds because
            // the adj_node is before the leaf_node, meaning the leaf_node is not the first child
            let ?leaf_2nd_entry = leaf_node.kvs[0] else Debug.trap("3. redistribute_leaf_keys: accessed a null value");
            let leaf_node_key = leaf_2nd_entry.0;

            let key_index = leaf_node.index - 1 : Nat;
            parent.keys[key_index] := ?leaf_node_key;
        } else {
            // and vice versa
            let ?adj_2nd_entry = adj_node.kvs[0] else Debug.trap("4. redistribute_leaf_keys: accessed a null value");
            let adj_node_key = adj_2nd_entry.0;

            let key_index = adj_node.index - 1 : Nat;
            parent.keys[key_index] := ?adj_node_key;
        };

        // update parent max
        if (is_adj_node_equal_to_parent_max) {
            switch(parent.max, adj_node.max){
                case (?parent_max, ?adj_max) {
                    if (cmp_key(parent_max.0, adj_max.0) != #equal) {
                        parent.max := ?(parent_max.0, parent_max.1, leaf_node.index);
                    };
                };
                case (_, _) {};
            };
        };

    };

    // merges two leaf nodes into the left node
    public func merge<K, V>(
        left : Leaf<K, V>,
        right : Leaf<K, V>,
        cmp_key : CmpFn<K>,
        cmp_val : CmpFn<V>,
    ) {
        var i = 0;
        var is_updated = false;

        // merge right into left
        for (_ in Iter.range(0, right.count - 1)) {
            let opt_kv = right.kvs[i];
            ArrayMut.insert(left.kvs, left.count + i, opt_kv, left.count);

            let ?kv = opt_kv else Debug.trap("Leaf.merge: kv is null");
            Common.update_leaf_fields(left, cmp_val, left.count + i, kv.0, kv.1);

            i += 1;
        };

        left.count += right.count;

        // update leaf pointers
        left.next := right.next;
        switch (left.next) {
            case (?next) next.prev := ?left;
            case (_) {};
        };

        let ?parent = left.parent else Debug.trap("Leaf.merge: parent is null");

        // if the max value was in the right node,
        // after the merge fn it will be in the left node
        // so we need to update the parent key with the new max value in the left node
        let ?right_max = right.max else Debug.trap("Leaf.merge: right max is null");
        let ?parent_max = parent.max else Debug.trap("Leaf.merge: parent max is null");
        if (parent_max.2 == right.index) {
            parent.max := ?(parent_max.0, parent_max.1, left.index);
        };

        // update parent keys
        ignore ArrayMut.remove(parent.keys, right.index - 1 : Nat, parent.count - 1 : Nat);

        // remove right from parent
        do {
            var i = right.index;
            while (i < (parent.count - 1 : Nat)) {
                parent.children[i] := parent.children[i + 1];

                let ?child = parent.children[i] else Debug.trap("Leaf.merge: accessed a null value");

                switch (child) {
                    case (#leaf(node) or #branch(node) : CommonNodeFields<K, V>) {
                        node.index := i;
                    };
                };

                // update max with prev index
                Common.update_branch_fields(parent, cmp_val, i + 1, child);

                i += 1;
            };

            parent.children[parent.count - 1] := null;
            parent.count -= 1;

            // update the max field index
            switch(parent.max){
                case (?max) {
                    if (max.2 > right.index) {
                        parent.max := ?(max.0, max.1, max.2 - 1);
                    }
                };
                case (_) {};
            };
        };
    };

    public func toText<K, V>(self : Leaf<K, V>, key_to_text : (K) -> Text, val_to_text : (V) -> Text) : Text {
        var t = "leaf { index: " # debug_show self.index # ", count: " # debug_show self.count # ", kvs: ";

        t #= debug_show Array.map(
            Array.freeze(self.kvs),
            func(opt_kv : ?(K, V)) : Text {
                switch (opt_kv) {
                    case (?kv) "(" # key_to_text(kv.0) # ", " # val_to_text(kv.1) # ")";
                    case (_) "null";
                };
            },
        );

        t #= " }";

        t;
    };
};
