import Iter "mo:base/Iter";
import Debug "mo:base/Debug";
import Array "mo:base/Array";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Order "mo:base/Order";

import Itertools "mo:itertools/Iter";

// import T "Types";
import InternalTypes "Types";
// import Leaf "Leaf";
import Utils "Utils";
import ArrayMut "ArrayMut";

module Branch {
    type Order = Order.Order;
    public type Branch<K, V, Extra> = InternalTypes.Branch<K, V, Extra>;
    type Node<K, V, Extra> = InternalTypes.Node<K, V, Extra>;
    type CmpFn<K> = InternalTypes.CmpFn<K>;
    type CommonNodeFields<K, V, Extra> = InternalTypes.CommonNodeFields<K, V, Extra>;

    public func new<K, V, Extra>(
        order : Nat,
        opt_keys : ?[var ?K],
        opt_children : ?[var ?Node<K, V, Extra>],
        gen_id: () -> Nat,
        default_fields: Extra,
        opt_update_fields: ?((Extra, Nat, Node<K, V, Extra>) -> ())
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

        let update_fields = switch(opt_update_fields) {
            case (?fn) fn;
            case (_) func (_: Any, _: Any, _: Any) {};
        };

        let children = switch (opt_children) {
            case (?children) { children };
            case (_) {
                self.keys := Array.init<?K>(order - 1, null);
                self.children := Array.init<?Node<K, V, Extra>>(order, null);
                return self;
            };
        };

        var count = 0;

        switch (children[0]) {
            case (? #leaf(node)) {
                node.parent := ?self;
                node.index := 0;
                count += 1;
                self.subtree_size += node.count;
                
                update_fields(self.fields, 0, #leaf(node));
            };
            case (?#branch(node)){
                node.parent := ?self;
                node.index := 0;
                count += 1;
                self.subtree_size += node.subtree_size;

                update_fields(self.fields, 0, #branch(node));
            };
            case (_) Debug.trap("Branch.new: should replace the opt_children input with a null value ");
        };

        let keys = switch(opt_keys){
            case (?keys){
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
                keys
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
                                node.index := count;
                                count += 1;
                                self.subtree_size += node.count;

                                update_fields(self.fields, child_index, #leaf(node));

                                switch (node.kvs[0]) {
                                    case (?kv) ?kv.0;
                                    case (_) null;
                                };
                            };
                            case (? #branch(node)) {
                                node.parent := ?self;
                                node.index := count;
                                count += 1;
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
        self.count := count;

        self;
    };
};