import Iter "mo:base/Iter";
import Debug "mo:base/Debug";
import Array "mo:base/Array";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Order "mo:base/Order";

import Itertools "mo:itertools/Iter";

// import T "Types";
import InternalTypes "Types";
import InternalMethods "Methods";
// import Leaf "Leaf";
import Utils "Utils";
import ArrayMut "ArrayMut";

module Branch {
    type Order = Order.Order;
    type CmpFn<K> = InternalTypes.CmpFn<K>;
    type CommonNodeFields<K, V, Extra> = InternalTypes.CommonNodeFields<K, V, Extra>;

    type BpTree<K, V, Extra> = InternalTypes.BpTree<K, V, Extra>;
    type Node<K, V, Extra> = InternalTypes.Node<K, V, Extra>;
    type Leaf<K, V, Extra> = InternalTypes.Leaf<K, V, Extra>;
    type Branch<K, V, Extra> = InternalTypes.Branch<K, V, Extra>;

    type KvUpdateFieldFn<K, V, Extra> = InternalTypes.KvUpdateFieldFn<K, V, Extra>;
    type NodeUpdateFieldFn<K, V, Extra> = InternalTypes.NodeUpdateFieldFn<K, V, Extra>;

    public func new<K, V, Extra>(
        order : Nat,
        opt_keys : ?[var ?K],
        opt_children : ?[var ?Node<K, V, Extra>],
        gen_id : () -> Nat,
        default_fields : Extra,
        opt_update_fields : ?(NodeUpdateFieldFn<K, V, Extra>),
    ) : Branch<K, V, Extra> {

        let self : Branch<K, V, Extra> = {
            id = gen_id();
            var parent = null;
            var index = 0;
            var keys = [var];
            var children = [var];
            var count = 0;
            var subtree_size = 0;
            fields = default_fields;
        };

        let update_fields = switch (opt_update_fields) {
            case (?fn) fn;
            case (_) func(_ : Any, _ : Any, _ : Any) {};
        };

        let children = switch (opt_children) {
            case (?children) { children };
            case (_) {
                self.keys := Array.init<?K>(order - 1, null);
                self.children := Array.init<?Node<K, V, Extra>>(order, null);
                return self;
            };
        };

        switch (children[0]) {
            case (? #leaf(node)) {
                node.parent := ?self;
                node.index := 0;
                self.count += 1;
                self.subtree_size += node.count;

                update_fields(self.fields, 0, #leaf(node));
            };
            case (? #branch(node)) {
                node.parent := ?self;
                node.index := 0;
                self.count += 1;
                self.subtree_size += node.subtree_size;

                update_fields(self.fields, 0, #branch(node));
            };
            case (_) Debug.trap("Branch.new: should replace the opt_children input with a null value ");
        };

        let keys = switch (opt_keys) {
            case (?keys) {
                for (child in Itertools.skip(children.vals(), 1)) {
                    switch (child) {
                        case (? #leaf(node)) {
                            node.parent := ?self;
                            node.index := self.count;
                            self.count += 1;
                            self.subtree_size += node.count;

                            update_fields(self.fields, node.index, #leaf(node));
                        };
                        case (? #branch(node)) {
                            node.parent := ?self;
                            node.index := self.count;
                            self.count += 1;
                            self.subtree_size += node.subtree_size;

                            update_fields(self.fields, node.index, #branch(node));

                        };
                        case (_) {};
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

                                update_fields(self.fields, child_index, #leaf(node));

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

                                update_fields(self.fields, child_index, #branch(node));

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

    public func update_median_key<K, V, Extra>(_parent : Branch<K, V, Extra>, index : Nat, new_key : K) {
        var parent = _parent;
        var i = index;

        while (i == 0) {
            i := parent.index;
            let ?__parent = parent.parent else return; // occurs when key is the first key in the tree
            parent := __parent;
        };

        parent.keys[i - 1] := ?new_key;
    };

    public func split<K, V, Extra>(
        node : Branch<K, V, Extra>,
        child : Node<K, V, Extra>,
        child_index : Nat,
        first_child_key : K,
        gen_id : () -> Nat,
        default_fields : Extra,
        opt_reset_fields : ?((Extra) -> ()),
        opt_update_fields : ?NodeUpdateFieldFn<K, V, Extra>,
    ) : Branch<K, V, Extra> {
        let arr_len = node.count;
        let median = (arr_len / 2) + 1;

        let is_elem_added_to_right = child_index >= median;

        var median_key = ?first_child_key;

        var offset = if (is_elem_added_to_right) 0 else 1;
        var already_inserted = false;

        let right_keys = Array.init<?K>(node.keys.size(), null);

        let right_children = Utils.tabulate_var<Node<K, V, Extra>>(
            node.children.size(),
            node.count + 1 - median,
            func(i : Nat) : ?Node<K, V, Extra> {

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
                case (? #branch(node) or ? #leaf(node) : ?CommonNodeFields<K, V, Extra>) {
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

        let right_node = switch (node.children[0]) {
            case (? #leaf(_)) Branch.new(node.children.size(), null, ?right_children, gen_id, default_fields, opt_update_fields);
            case (? #branch(_)) {
                Branch.new(node.children.size(), ?right_keys, ?right_children, gen_id, default_fields, opt_update_fields);
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
        let ?reset_fields = opt_reset_fields else return right_node;
        let ?update_fields = opt_update_fields else return right_node;

        var i = 0;
        reset_fields(node.fields);
        while (i < node.count) {
            let ?child = node.children[i] else Debug.trap("Leaf.split: child is null");
            update_fields(node.fields, i, child);
            i += 1;
        };

        right_node;
    };

    public func shift_by<K, V, Extra>(self : Branch<K, V, Extra>, start : Nat, end : Nat, shift : Int) {
        if (shift == 0) return;

        if (shift > 0) {
            var i = end; // exclusive

            while (i > start) {
                let child = self.children[i - 1];
                self.children[i - 1] := null;

                let j = Int.abs(shift) + i - 1 : Nat;
                self.children[j] := child;

                switch (child) {
                    case (? #branch(node) or ? #leaf(node) : ?InternalTypes.CommonNodeFields<K, V, Extra>) {
                        node.index := j;
                    };
                    case (_) {};
                };

                i -= 1;
            };

            return;
        };

        var i = start;
        while (i < end) {
            let child = self.children[i];
            self.children[i] := null;

            let j = Int.abs(i + shift);
            self.children[j] := child;

            switch (child) {
                case (? #branch(node) or ? #leaf(node) : ?CommonNodeFields<K, V, Extra>) {
                    node.index := j;
                };
                case (_) {};
            };

            i += 1;
        };
    };

    public func put<K, V, Extra>(branch : Branch<K, V, Extra>, i : Nat, child : Node<K, V, Extra>) {
        branch.children[i] := ?child;

        switch (child) {
            case (#branch(node) or #leaf(node) : CommonNodeFields<K, V, Extra>) {
                node.parent := ?branch;
                node.index := i;
            };
        };
    };

    public func insert<K, V, Extra>(branch : Branch<K, V, Extra>, i : Nat, child : Node<K, V, Extra>) {

        var j = i;

        while (j < branch.count) {
            branch.children[j + 1] := branch.children[j];

            switch (branch.children[j + 1]) {
                case (? #branch(node) or ? #leaf(node) : ?CommonNodeFields<K, V, Extra>) {
                    node.parent := ?branch;
                    node.index := j + 1;
                };
                case (_) {};
            };
            j += 1;
        };

        branch.children[i] := ?child;

        switch (child) {
            case (#branch(node) or #leaf(node) : CommonNodeFields<K, V, Extra>) {
                node.parent := ?branch;
                node.index := i;
            };
        };

    };

    public func remove<K, V, Extra>(
        self : Branch<K, V, Extra>, 
        index : Nat, 
        count : Nat,
        opt_update_node_fields : ?NodeUpdateFieldFn<K, V, Extra>,
    ) : ?Node<K, V, Extra> {
        let removed = self.children[index];

        var i = index;
        while (i < (count - 1 : Nat)) {
            self.children[i] := self.children[i + 1];

            let ?child = self.children[i] else Debug.trap("Branch.remove: accessed a null value");

            switch (child) {
                case (#leaf(node) or #branch(node) : CommonNodeFields<K, V, Extra>) {
                    node.index := i;
                };
            };

            switch(opt_update_node_fields) {
                case (?update_node_fields) {
                    update_node_fields(self.fields, i, child);
                };
                case (_) {};
            };

            i += 1;
        };

        self.children[count - 1] := null;
        // self.count -=1;

        removed;
    };

    public func redistribute_keys<K, V, Extra>(
        branch_node : Branch<K, V, Extra>,
        opt_reset_fields : ?((Extra) -> ()),
        opt_update_node_fields : ?NodeUpdateFieldFn<K, V, Extra>,
    ) {
        var adj_node = branch_node;

        // retrieve adjacent node
        switch (branch_node.parent) {
            case (null) {};
            case (?parent) {
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
            };
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
                let ?val = Branch.remove(adj_node, j, adj_node.count - i : Nat, null) else Debug.trap("4. redistribute_branch_keys: accessed a null value");
                
                // no need to call update_fields as we are the adjacent node is before the leaf node 
                // which means that all its keys are less than the leaf node's keys
                Branch.put(branch_node, new_node_index, val);

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

        let ?reset_fields = opt_reset_fields else return;
        let ?update_node_fields = opt_update_node_fields else return;

        var i = 0;
        let left_node = if (adj_node.index < branch_node.index) adj_node else branch_node;
        reset_fields(left_node.fields);

        while (i < left_node.count) {
            let ?node = left_node.children[i] else Debug.trap("Leaf.redistribute_keys: kv is null");
            update_node_fields(left_node.fields, i, node);
            i += 1;
        };

        // update the parent fields with the updated adjacent and branch nodes
        update_node_fields(parent.fields, adj_node.index, #branch(adj_node));
        update_node_fields(parent.fields, branch_node.index, #branch(branch_node));
    };

    public func merge<K, V, Extra>(
        left: Branch<K, V, Extra>, 
        right: Branch<K, V, Extra>,
        opt_update_node_fields : ?NodeUpdateFieldFn<K, V, Extra>,
    ){
        assert left.index + 1 == right.index;

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
            switch(opt_update_node_fields) {
                case (?update_node_fields) {
                    update_node_fields(left.fields, left.count + i, child);
                };
                case (_) {};
            };
        };

        left.count += right.count;
        left.subtree_size += right_subtree_size;

        // update the parent fields with the updated left node
        switch (opt_update_node_fields) {
            case (?update_node_fields) {
                update_node_fields(parent.fields, left.index, #branch(left));
            };
            case (_) {};
        };

        // update parent keys
        ignore ArrayMut.remove(parent.keys, right.index - 1 : Nat, parent.count - 1 : Nat);
        ignore Branch.remove(parent, right.index, parent.count, opt_update_node_fields);
        parent.count -= 1;

    };
};
