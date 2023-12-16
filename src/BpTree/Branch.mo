import Iter "mo:base/Iter";
import Debug "mo:base/Debug";
import Array "mo:base/Array";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Order "mo:base/Order";

import T "Types";
import InternalTypes "../internal/Types";
import InternalBranch "../internal/Branch";
import Leaf "Leaf";
import Utils "../internal/Utils";
import ArrayMut "../internal/ArrayMut";

module Branch {
    type Order = Order.Order;
    public type Branch<K, V> = T.Branch<K, V>;
    type Node<K, V> = T.Node<K, V>;
    type BpTree<K, V> = T.BpTree<K, V>;
    type CmpFn<K> = InternalTypes.CmpFn<K>;
    type CommonNodeFields<K, V> = T.CommonNodeFields<K, V>;

    public func new<K, V>(
        bptree : BpTree<K, V>,
        opt_keys : ?[var ?K],
        opt_children : ?[var ?Node<K, V>],
    ) : Branch<K, V> {
        InternalBranch.new<K, V, ()>(bptree, opt_keys, opt_children, (), null);
    };

    public func shift_by<K, V>(self: Branch<K, V>, start: Nat, end: Nat, shift: Int){
        if (shift == 0) return;

        if (shift > 0 ){
            var i = end; // exclusive

            while (i > start){
                let child = self.children[i - 1];
                self.children[i - 1] := null;

                let j = Int.abs(shift) + i - 1 : Nat;
                self.children[j] := child;
                // Debug.print("shift_by: " # debug_show (i-1)  # " -> " # debug_show j);

                // type Shared<K, V> = T.Branch<K, V> and T.Leaf<K, V>;

                // type Fields<K, V> = {
                //     #leaf: Shared<K, V>;
                //     #branch: Shared<K, V>;
                // };

                switch (child) {
                    case (? #branch(node) or ? #leaf(node) : ?InternalTypes.CommonNodeFields<K, V, ()>) {
                        node.index := j;
                    };
                    case (_) {};
                };

                i -= 1;
            };

            return;
        };

        var i = start;
        while (i < end){
            let child = self.children[i];
            self.children[i] := null;

            let j = Int.abs(i + shift);
            self.children[j] := child;

            switch (child) {
                case (? #branch(node) or ? #leaf(node) : ?CommonNodeFields<K, V>) {
                    node.index := j;
                };
                case (_) {};
            };

            i += 1;
        };
    };

    public func put<K, V>(branch: Branch<K, V>, i: Nat, child: Node<K, V>){
        branch.children[i] := ?child;

        switch (child) {
            case (#branch(node) or  #leaf(node) : CommonNodeFields<K, V>) {
                node.parent := ?branch;
                node.index := i;
            };
        };
    };

    public func update_median_key<K, V>(_parent: Branch<K, V>, index: Nat, new_key: K){
        var parent = _parent;
        var i = index;

        while (i == 0){
            i:= parent.index;
            let ?__parent = parent.parent else return; // occurs when key is the first key in the tree
            parent := __parent;
        };

        parent.keys[i - 1] := ?new_key;
    };

    public func split<K, V>(node : Branch<K, V>, child : Node<K, V>, child_index : Nat, first_child_key : K, bptree: BpTree<K, V>) : Branch<K, V> {

        func new_branch(
            bptree : BpTree<K, V>,
            opt_keys : ?[var ?K],
            opt_children : ?[var ?Node<K, V>],
        ) : Branch<K, V> {
            InternalBranch.new<K, V, ()>(bptree, opt_keys, opt_children, (), null);
        };

        InternalBranch.split<K, V, ()>(node, child, child_index, first_child_key, bptree, new_branch);
    };

    public func redistribute_keys<K, V>(branch_node: Branch<K, V>){
        var adj_node = branch_node;
        
        // retrieve adjacent node
        switch(branch_node.parent){
            case (null) {};
            case (?parent){
                if (parent.count > 1){
                    if (branch_node.index != 0){
                        let ?#branch(left_adj_node) = parent.children[branch_node.index - 1] else Debug.trap("1. redistribute_branch_keys: accessed a null value");
                        adj_node := left_adj_node;
                    };

                    if (branch_node.index + 1 != parent.count){
                        let ?#branch(right_adj_node) = parent.children[branch_node.index + 1] else Debug.trap("2. redistribute_branch_keys: accessed a null value");
                        if (right_adj_node.count > adj_node.count){
                            adj_node := right_adj_node;
                        };
                    };
                }
            }
        };

        if (adj_node.index == branch_node.index) return; // no adjacent node to distribute data to

        let sum_count = branch_node.count + adj_node.count;
        let min_count_for_both_nodes = branch_node.children.size();

        if (sum_count < min_count_for_both_nodes) return; // not enough entries to distribute

        let data_to_move = (sum_count / 2) - branch_node.count : Nat;

        // every node from this point on has a parent because an adjacent node was found
        let ?parent = branch_node.parent else Debug.trap("3. redistribute_branch_keys: accessed a null value");
        // assert Utils.is_sorted<Nat>(branch_node.keys, Nat.compare);

        var moved_subtree_size = 0;

        // distribute data between adjacent nodes
        if (adj_node.index < branch_node.index){ 
            // adj_node is before branch_node
            var median_key = parent.keys[adj_node.index];

            ArrayMut.shift_by(branch_node.keys, 0, branch_node.count - 1 : Nat, data_to_move : Nat);
            Branch.shift_by(branch_node, 0, branch_node.count : Nat, data_to_move : Nat);
            var i = 0;
            for (_ in Iter.range(0, data_to_move - 1)){
                let j = adj_node.count - i - 1 : Nat;
                branch_node.keys[data_to_move - i - 1] := median_key;
                let ?mk = ArrayMut.remove(adj_node.keys, j - 1: Nat, adj_node.count - 1 : Nat) else Debug.trap("4. redistribute_branch_keys: accessed a null value");
                median_key := ?mk;
                
                let val = Utils.unwrap(Branch.remove(adj_node, j, adj_node.count - i: Nat), "4. redistribute_branch_keys: accessed a null value");
                Branch.put(branch_node, data_to_move - i - 1: Nat, val);

                switch(val){
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

        }else { 
            // adj_node is after branch_node
            var j = branch_node.count : Nat;
            var median_key = parent.keys[branch_node.index];
            var i = 0;

            for (_ in Iter.range(0, data_to_move - 1)){
                ArrayMut.insert(branch_node.keys, branch_node.count + i - 1: Nat, median_key, branch_node.count - 1: Nat);
                median_key := adj_node.keys[i];

                let ?val = adj_node.children[i] else Debug.trap("5. redistribute_branch_keys: accessed a null value");
                Branch.insert(branch_node, branch_node.count + i, val);

                switch(val){
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
    };

    public func merge<K, V>(left: Branch<K, V>, right: Branch<K, V>){
        assert left.index + 1 == right.index;
        // Debug.print("merge branch");

        // if there are two adjacent nodes then there must be a parent
        let ?parent = left.parent else Debug.trap("1. merge_branch_nodes: accessed a null value");

        var median_key = parent.keys[right.index - 1];
        let right_subtree_size = right.subtree_size;
        // merge right into left
        for (i in Iter.range(0, right.count - 1)){
            ArrayMut.insert(left.keys, left.count + i - 1 : Nat, median_key, left.count - 1 : Nat);
            median_key := right.keys[i];

            let ?child = right.children[i] else Debug.trap("2. merge_branch_nodes: accessed a null value");
            Branch.insert(left, left.count + i, child);
        };

        left.count += right.count;
        left.subtree_size += right_subtree_size;

        // update parent keys
        ignore ArrayMut.remove(parent.keys, right.index - 1 : Nat, parent.count - 1 : Nat);
        ignore Branch.remove(parent, right.index, parent.count);
        parent.count -= 1;

    };

    public func remove<K, V>(self : Branch<K, V>, index : Nat, count: Nat) : ?Node<K, V> {
        let removed = self.children[index];

        var i = index;
        while (i < (count - 1 : Nat)) {
            self.children[i] := self.children[i + 1];

            switch (self.children[i]) {
                case (? #leaf(node) or ? #branch(node) : ?CommonNodeFields<K, V>) {
                    node.index := i;
                };
                case (_) Debug.trap("Branch.remove: accessed a null value");
            };
            i += 1;
        };

        self.children[count - 1] := null;
        // self.count -=1;

        removed;
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

    public func equal<K, V>(a : Branch<K, V>, b : Branch<K, V>, cmp : CmpFn<K>) : Bool {
        for (i in Iter.range(0, a.keys.size() - 2)) {
            let res = switch (a.keys[i], b.keys[i]) {
                case (?v1, ?v2) {
                    cmp(v1, v2) == #equal;
                };
                case (null, null) true;
                case (_) false;
            };

            if (not res) return false;
        };

        for (i in Iter.range(0, a.children.size() - 1)) {
            let res = switch (a.children[i], b.children[i]) {
                case (? #leaf(v1), ? #leaf(v2)) {
                    Leaf.equal(v1, v2, cmp);
                };
                case (? #branch(v1), ? #branch(v2)) {
                    equal(v1, v2, cmp);
                };
                case (null, null) true;
                case (_) false;
            };
        };

        true;
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
