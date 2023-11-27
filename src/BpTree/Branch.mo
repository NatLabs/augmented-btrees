import Iter "mo:base/Iter";
import Debug "mo:base/Debug";
import Array "mo:base/Array";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Order "mo:base/Order";

import T "Types";
import InternalTypes "../internal/Types";
import Leaf "Leaf";
import Utils "../internal/Utils";
import ArrayMut "../internal/ArrayMut";

module Branch {
    type Order = Order.Order;
    public type Branch<K, V> = T.Branch<K, V>;
    type Node<K, V> = T.Node<K, V>;
    type CmpFn<K> = InternalTypes.CmpFn<K>;
    type SharedNode<K, V> = T.SharedNode<K, V>;

    public func new<K, V>(
        order : Nat,
        opt_children : ?[var ?Node<K, V>],
    ) : Branch<K, V> {

        let self : Branch<K, V> = {
            var parent = null;
            var index = 0;
            var keys = [var];
            var children = [var];
            var count = 0;
            // var subtree_size = 0;
        };

        let children = switch (opt_children) {
            case (?children) { children };
            case (_) {
                self.keys := Array.init<?K>(order - 1, null);
                self.children := Array.init<?Node<K, V>>(order, null);
                return self;
            };
        };

        var count = 0;

        switch (children[0]) {
            case (? #leaf(node) or ? #branch(node) : ?SharedNode<K, V>) {
                node.parent := ?self;
                node.index := 0;
                count += 1;
            };
            case (_) Debug.trap("Branch.new: should replace the opt_children input with a null value ");
        };

        let keys = Array.tabulateVar<?K>(
            order - 1 : Nat,
            func(i : Nat) : ?K {
                switch (children[i + 1]) {
                    case (? #leaf(node)) {
                        node.parent := ?self;
                        node.index := count;
                        count += 1;

                        switch (node.kvs[0]) {
                            case (?kv) ?kv.0;
                            case (_) null;
                        };
                    };
                    case (? #branch(node)) {
                        node.parent := ?self;
                        node.index := count;
                        count += 1;
                        node.keys[0];
                    };
                    case (_) null;
                };
            },
        );

        self.keys := keys;
        self.children := children;
        self.count := count;

        self;
    };

    public func newWithKeys<K, V>(keys : [var ?K], children : [var ?Node<K, V>]) : Branch<K, V> {
        let self : Branch<K, V> = {
            var parent = null;
            var index = 0;
            var keys = keys;
            var children = children;
            var count = 0;
        };

        for (child in children.vals()) {
            switch (child) {
                case (? #leaf(node)) {
                    node.parent := ?self;
                    node.index := self.count;
                    self.count += 1;
                };
                case (? #branch(node)) {
                    node.parent := ?self;
                    node.index := self.count;
                    self.count += 1;
                };
                case (_) {};
            };
        };

        self;
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
                switch (child) {
                    case (? #branch(node) or ? #leaf(node) : ?SharedNode<K, V>) {
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
                case (? #branch(node) or ? #leaf(node) : ?SharedNode<K, V>) {
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
            case (#branch(node) or  #leaf(node) : SharedNode<K, V>) {
                node.parent := ?branch;
                node.index := i;
            };
        };
    };

    public func split<K, V>(node : Branch<K, V>, child : Node<K, V>, child_index : Nat, first_child_key : K) : Branch<K, V> {
        let arr_len = node.count;
        let median = (arr_len / 2) + 1;

        let is_elem_added_to_right = child_index >= median;

        var median_key = ?first_child_key;

        var offset = if (is_elem_added_to_right) 0 else 1;
        var already_inserted = false;

        let right = Branch.new<K, V>(node.children.size(), null);

        let right_keys = Array.init<?K>(node.keys.size(), null);

        let right_children = Array.tabulateVar<?Node<K, V>>(
            node.children.size(),
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
                    case (? #branch(node) or ? #leaf(node) : ?SharedNode<K, V>) {
                        node.index := i;
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
                case (? #branch(node) or ? #leaf(node) : ?SharedNode<K, V>) {
                    node.index := j;
                };
                case (_) {};
            };

            j -= 1;
        };

        if (j == child_index) {
            if (j > 0) {
                node.keys[j - 1] := ?first_child_key;
            } else {
                let key : ?K = switch (node.children[j]) {
                    case (? #branch(node)) {
                        node.keys[0];
                    };
                    case (? #leaf(node)) {
                        switch (node.kvs[0]) {
                            case (?kv) ?kv.0;
                            case (_) Debug.trap("split_branch: accessed a null value");
                        };
                    };
                    case (_) Debug.trap("split_branch: accessed a null value");
                };

                node.keys[0] := key;
            };

            node.children[j] := ?child;
        };

        node.count := median;
        let right_cnt = node.children.size() + 1 - median : Nat;

        let right_node = switch (node.children[0]) {
            case (? #leaf(_)) Branch.new(node.children.size(), ?right_children);
            case (? #branch(_)) {
                Branch.newWithKeys<K, V>(right_keys, right_children);
                // Branch.new( node.children.size(), ?right_children);
            };
            case (_) Debug.trap("right_node: accessed a null value");
        };

        right_node.index := node.index + 1;

        right_node.count := right_cnt;
        right_node.parent := node.parent;

        // store the first key of the right node at the end of the keys in left node
        // no need to delete as the value will get overwritten because it exceeds the count position
        right_node.keys[right_node.keys.size() - 1] := median_key;

        right_node;
    };

    public func redistribute_keys(branch_node: Branch<Nat, Nat>){
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
        // Debug.print("redistribute branch");
        // assert Utils.is_sorted<Nat>(branch_node.keys, Nat.compare);

        // distribute data between adjacent nodes
        if (adj_node.index < branch_node.index){ 
            // adj_node is before branch_node
            // Debug.print("chose left adj node");
            var median_key = parent.keys[adj_node.index];

            // Debug.print("branch keys " # debug_show Array.freeze(branch_node.keys));
            ArrayMut.shift_by(branch_node.keys, 0, branch_node.count - 1 : Nat, data_to_move : Nat);
            Branch.shift_by(branch_node, 0, branch_node.count : Nat, data_to_move : Nat);
            var i = 0;
            for (_ in Iter.range(0, data_to_move - 1)){
                let j = adj_node.count - i - 1 : Nat;
                branch_node.keys[data_to_move - i - 1] := median_key;
                let ?mk = ArrayMut.remove(adj_node.keys, j - 1: Nat, adj_node.count - 1 : Nat) else Debug.trap("4. redistribute_branch_keys: accessed a null value");
                median_key := ?mk;
                
                // Debug.print("branch keys (" # debug_show i # ") is " # debug_show Array.freeze(branch_node.keys));
                let val = Utils.unwrap(Branch.remove(adj_node, j, adj_node.count - i: Nat), "4. redistribute_branch_keys: accessed a null value");
                Branch.put(branch_node, data_to_move - i - 1: Nat, val);
                i += 1;
            };

            parent.keys[adj_node.index] := median_key;

        }else { 
            // adj_node is after branch_node
            // Debug.print("chose right adj node");

            var j = branch_node.count : Nat;
            var median_key = parent.keys[branch_node.index];
            var i = 0;

            for (_ in Iter.range(0, data_to_move - 1)){
                ArrayMut.insert(branch_node.keys, branch_node.count + i - 1: Nat, median_key, branch_node.count - 1: Nat);
                median_key := adj_node.keys[i];

                let ?val = adj_node.children[i] else Debug.trap("5. redistribute_branch_keys: accessed a null value");
                Branch.insert(branch_node, branch_node.count + i, val);

                i += 1;
            };

            ArrayMut.shift_by(adj_node.keys, i, adj_node.count - 1 : Nat, -data_to_move : Int);
            Branch.shift_by(adj_node, i, adj_node.count : Nat, -data_to_move : Int);

            parent.keys[branch_node.index] := median_key;

        };

        adj_node.count -= data_to_move;
        branch_node.count += data_to_move;

        // Debug.print("adj_node keys " # debug_show Array.freeze(adj_node.keys));
        // Debug.print("branch_node keys " # debug_show Array.freeze(branch_node.keys));

        // assert Utils.validate_indexes<Nat, Nat>(branch_node.children, branch_node.count);
        // assert Utils.validate_array_equal_count(branch_node.children, branch_node.count);
        let cmp = func((a, _) : (Nat, Nat), (b, _): (Nat, Nat)): Order = Nat.compare(a, b);
        // assert Utils.is_sorted<Nat>(branch_node.keys, Nat.compare);

        // assert Utils.validate_array_equal_count(adj_node.children, adj_node.count);
        // assert Utils.is_sorted<Nat>(adj_node.keys, Nat.compare);

        // assert Utils.validate_indexes<Nat, Nat>(parent.children, parent.count);
        // assert Utils.validate_array_equal_count(parent.children, parent.count);
        // assert Utils.is_sorted<Nat>(parent.keys, Nat.compare);
        
    };

    public func merge(left: Branch<Nat, Nat>, right: Branch<Nat, Nat>){
        assert left.index + 1 == right.index;
        // Debug.print("merge branch");

        // if there are two adjacent nodes then there must be a parent
        let ?parent = left.parent else Debug.trap("1. merge_branch_nodes: accessed a null value");

        var median_key = parent.keys[right.index - 1];

        // merge right into left
        for (i in Iter.range(0, right.count - 1)){
            ArrayMut.insert(left.keys, left.count + i - 1 : Nat, median_key, left.count - 1 : Nat);
            median_key := right.keys[i];

            let ?child = right.children[i] else Debug.trap("2. merge_branch_nodes: accessed a null value");
            Branch.insert(left, left.count + i, child);
        };

        left.count += right.count;

        let cmp = func((a, _) : (Nat, Nat), (b, _): (Nat, Nat)): Order = Nat.compare(a, b);

        // assert Utils.validate_indexes<Nat, Nat>(left.children, left.count);
        // assert Utils.validate_array_equal_count(left.keys, left.count - 1);
        // assert Utils.validate_array_equal_count(left.children, left.count);
        // assert Utils.is_sorted<Nat>(left.keys, Nat.compare);


        // update parent keys
        ignore ArrayMut.remove(parent.keys, right.index - 1 : Nat, parent.count - 1 : Nat);
        ignore Branch.remove(parent, right.index, parent.count);
        parent.count -= 1;

        // assert Utils.validate_indexes<Nat, Nat>(parent.children, parent.count);
        // assert Utils.validate_array_equal_count(parent.keys, parent.count - 1);
        // assert Utils.validate_array_equal_count(parent.children, parent.count);
        // assert Utils.is_sorted<Nat>(parent.keys, Nat.compare);


    };

    public func remove(self : Branch<Nat, Nat>, index : Nat, count: Nat) : ?Node<Nat, Nat> {
        // Debug.print("Branch.remove: index: " # debug_show index # ", count: " # debug_show self.count);
        // Debug.print("Branch.remove: keys: " # debug_show Array.freeze(self.keys));
        // Debug.print("Branch.remove: self: " # debug_show toText(self, Nat.toText, Nat.toText));
        let removed = self.children[index];

        var i = index;
        while (i < (count - 1 : Nat)) {
            self.children[i] := self.children[i + 1];

            switch (self.children[i]) {
                case (? #leaf(node) or ? #branch(node) : ?SharedNode<Nat, Nat>) {
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
                case (? #branch(node) or ? #leaf(node) : ?SharedNode<K, V>) {
                    node.parent := ?branch;
                    node.index := j + 1;
                };
                case (_) {};
            };
            j += 1;
        };

        branch.children[i] := ?child;

        switch (child) {
            case (#branch(node) or #leaf(node) : SharedNode<K, V>) {
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

    public func toText<K, V>(self : Branch<K, V>, key_to_text : (K) -> Text, val_to_text : (V) -> Text) : Text {
        var t = "branch { index: " # debug_show self.index # ", count: " # debug_show self.count # ", keys: ";
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
