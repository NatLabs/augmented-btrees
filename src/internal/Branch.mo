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

    type UpdateBranchFieldsFn<K, V, Extra> = InternalTypes.UpdateBranchFieldsFn<K, V, Extra>;

    public func new<K, V, Extra>(
        order : Nat,
        opt_keys : ?[var ?K],
        opt_children : ?[var ?Node<K, V, Extra>],
        gen_id: () -> Nat,
        default_fields : Extra,
        opt_update_fields : ?(UpdateBranchFieldsFn<K, V, Extra>),
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

    public func update_median_key<K, V, Extra>(_parent: Branch<K, V, Extra>, index: Nat, new_key: K){
        var parent = _parent;
        var i = index;

        while (i == 0){
            i:= parent.index;
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
        default_fields: Extra,
        opt_reset_fields: ?((Extra) -> ()),
        opt_update_fields: ?UpdateBranchFieldsFn<K, V, Extra>,
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
        while ( i < node.count ) {
            let ?child = node.children[i] else Debug.trap("Leaf.split: child is null");
            update_fields(node.fields, i, child);
            i += 1;
        };

        

        right_node;
    };
};
