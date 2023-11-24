import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Option "mo:base/Option";

import BpTreeBranch "../BpTree/Branch";
import T "Types";
import BpTree "../BpTree";

import Utils "../internal/Utils";
import InternalTypes "../internal/Types";

module {
    public type Branch<K, V> = T.Branch<K, V>;
    type Node<K, V> = T.Node<K, V>;
    type SharedNode<K, V> = T.SharedNode<K, V>;
    type CmpFn<K> = InternalTypes.CmpFn<K>;

    public func new<K, V>(
        order : Nat,
        cmp: CmpFn<K>,
        opt_children : ?[var ?Node<K, V>],
    ) : Branch<K, V> {

        let self : Branch<K, V> = {
            var parent = null;
            var index = 0;
            var keys = [var];
            var children = [var];
            var count = 0;
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

        var count = 0;

        var max : K = switch (children[0]) {
            case (? #leaf(node) or ? #branch(node) : ?SharedNode<K, V>) {
                node.parent := ?self;
                node.index := 0;
                count += 1;

                let ?node_max = node.max else Debug.trap("Branch.new: should have a max value");
                node_max;
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

                        let ?node_max = node.max else Debug.trap("Branch.new: should have a max value");

                        if (cmp(node_max, max) == #greater) {
                            max := node_max;
                        };

                        switch (node.kvs[0]) {
                            case (?kv) ?kv.0;
                            case (_) null;
                        };
                    };
                    case (? #branch(node)) {
                        node.parent := ?self;
                        node.index := count;
                        count += 1;

                        let ?node_max = node.max else Debug.trap("Branch.new: should have a max value");

                        if (cmp(node_max, max) == #greater) {
                            max := node_max;
                        };

                        node.keys[0];
                    };
                    case (_) null;
                };
            },
        );

        self.keys := keys;
        self.children := children;
        self.count := count;
        self.max := ?max;

        self;
    };

    // public func newWithKeys<K, V>(cmp: CmpFn<K>, keys : [var ?K], children : [var ?Node<K, V>]) : Branch<K, V> {
    //     let self : Branch<K, V> = {
    //         var parent = null;
    //         var index = 0;
    //         var keys = keys;
    //         var children = children;
    //         var count = 0;
    //         var max = null;
    //     };

    //     for (child in children.vals()) {
    //         switch (child) {
    //             case (? #leaf(node)) {
    //                 node.parent := ?self;
    //                 node.index := self.count;
    //                 self.count += 1;

    //                 let ?node_max = node.max else Debug.trap("Branch.new: should have a max value");

    //                 switch(cmp(node_max, max)) {
    //                     case (#greater) max := node_max;
    //                     case (_) {};
    //                 };
    //             };
    //             case (? #branch(node)) {
    //                 node.parent := ?self;
    //                 node.index := self.count;
    //                 self.count += 1;

    //                 let ?node_max = node.max else Debug.trap("Branch.new: should have a max value");

    //                 switch(cmp(node_max, max)) {
    //                     case (#greater) max := node_max;
    //                     case (_) {};
    //                 };
    //             };
    //             case (_) {};
    //         };
    //     };

    //     self;
    // };

}