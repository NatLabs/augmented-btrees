import Prim "mo:prim";

import Option "mo:base/Option";
import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Order "mo:base/Order";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Buffer "mo:base/Buffer";
import Deque "mo:buffer-deque/BufferDeque";

import Utils "Utils";

module BpTree {
    type Iter<A> = Iter.Iter<A>;
    type Order = Order.Order;
    type CmpFn<A> = (A, A) -> Order;

    public type BpTree<K, V> = {
        order : Nat;
        var root : Node<K, V>;
        var size : Nat;
    };

    // type Leaf<K, V> = {
    //     var parent : ?Branch<K, V>;
    //     var index : Nat;
    //     kvs : [var ?(K, V)];
    //     var count : Nat;
    //     var next : ?Leaf<K, V>;
    // };

    // type Branch<K, V> = {
    //     var parent : ?Branch<K, V>;
    //     var index : Nat;
    //     keys : [var ?K];
    //     children : [var ?Node<K, V>];
    //     var count : Nat;
    // };

    type SharedNodeFields<K, V> = {
        var count : Nat;
        var index : Nat;
        var parent : ?Branch<K, V>;
    };

    type SharedNode<K, V> = {
        #leaf : SharedNodeFields<K, V>;
        #branch : SharedNodeFields<K, V>;
    };

    public module Leaf {
        public type Leaf<K, V> = {
            var parent : ?Branch<K, V>;
            var index : Nat;
            kvs : [var ?(K, V)];
            var count : Nat;
            var next : ?Leaf<K, V>;
        };

        public func new<K, V>(order : Nat, opt_kvs : ?[var ?(K, V)]) : Leaf<K, V> {
            {
                var parent = null;
                var index = 0;
                kvs = Option.get(opt_kvs, Array.init<?(K, V)>(order, null));
                var count = 0;
                var next = null;
            };
        };

        public func equal<K, V>(a : Leaf<K, V>, b : Leaf<K, V>, cmp : CmpFn<K>) : Bool {
            for (i in Iter.range(0, a.kvs.size() - 1)) {
                let res = switch (a.kvs[i], b.kvs[i]) {
                    case (?v1, ?v2) {
                        cmp(v1.0, v2.0) == #equal;
                    };
                    case (_) false;
                };

                if (not res) return false;
            };

            true;
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

    public module Branch {
        public type Branch<K, V> = {
            var parent : ?Branch<K, V>;
            var index : Nat;
            var keys : [var ?K];
            var children : [var ?Node<K, V>];
            var count : Nat;
        };

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
                    // Debug.print("i = " # debug_show i);
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

    module Node {
        public type Node<K, V> = {
            #leaf : Leaf<K, V>;
            #branch : Branch<K, V>;
        };

        public func newLeaf<K, V>(order : Nat, opt_kvs : ?[var ?(K, V)]) : Leaf<K, V> {
            {
                var parent = null;
                var index = 0;
                kvs = Option.get(opt_kvs, Array.init<?(K, V)>(order, null));
                var count = 0;
                var next = null;
            };
        };

        public func newBranch<K, V>(
            order : Nat,
            opt_keys : ?[var ?K],
            opt_children : ?[var ?Node<K, V>],
        ) : Branch<K, V> {
            {
                var parent = null;
                var index = 0;
                var keys = Option.get(opt_keys, Array.init<?K>(order - 1, null));
                var children = Option.get(opt_children, Array.init<?Node<K, V>>(order, null));
                var count = 0;
            };
        };
    };

    public type Node<K, V> = Node.Node<K, V>;
    public type Leaf<K, V> = Leaf.Leaf<K, V>;
    public type Branch<K, V> = Branch.Branch<K, V>;

    public func new<K, V>() : BpTree<K, V> {
        BpTree.newWithOrder<K, V>(32);
    };

    public func newWithOrder<K, V>(order : Nat) : BpTree<K, V> {
        // assert order >= 4 and order <= 512;

        {
            order;
            var root = #leaf(Node.newLeaf<K, V>(order, null));
            var size = 0;
        };
    };

    public func size<K, V>(self : BpTree<K, V>) : Nat {
        self.size;
    };

    public func depth<K, V>(bptree : BpTree<K, V>) : Nat {
        var node = ?bptree.root;
        var depth = 0;

        label while_loop loop {
            switch (node) {
                case (? #branch(n)) {
                    node := n.children[0];
                    depth += 1;
                };
                case (? #leaf(_)) {
                    return depth + 1;
                };
                case (_) Debug.trap("depth: accessed a null value");
            };
        };

        depth;
    };

    type MultiCmpFn<A, B> = (A, B) -> Order;

    public func binary_search<A, B>(arr : [var ?A], cmp : MultiCmpFn<B, A>, search_key : B, arr_len : Nat) : Int {
        if (arr_len == 0) return -1; // should insert at index Int.abs(i + 1)
        var l = 0;

        // arr_len will always be between 4 and 512
        var r = arr_len - 1 : Nat;

        while (l < r) {
            let mid = (l + r) / 2;

            let ?val = arr[mid] else Debug.trap("1. binary_search: accessed a null value");

            switch (cmp(search_key, val)) {
                case (#less) {
                    r := mid;
                };
                case (#greater) {
                    l := mid + 1;
                };
                case (#equal) {
                    return mid;
                };
            };
        };

        let insertion = l;

        // Check if the insertion point is valid
        // return the insertion point but negative and subtracting 1 indicating that the key was not found
        // such that the insertion index for the key is Int.abs(insertion) - 1
        // [0,  1,  2]
        //  |   |   |
        // -1, -2, -3
        switch (arr[insertion]) {
            case (?val) {
                switch (cmp(search_key, val)) {
                    case (#equal) insertion;
                    case (#less) -(insertion + 1);
                    case (#greater) -(insertion + 2);
                };
            };
            case (_) {
                Debug.print("insertion = " # debug_show insertion);
                Debug.print("arr_len = " # debug_show arr_len);
                Debug.print(
                    "arr = " # debug_show Array.map(
                        Array.freeze(arr),
                        func(opt_val : ?A) : Text {
                            switch (opt_val) {
                                case (?val) "1";
                                case (_) "0";
                            };
                        },
                    )
                );
                Debug.trap("2. binary_search: accessed a null value");
            };
        };

    };

    public func binary_search_n<T>(arr : [var ?T], cmp : CmpFn<T>, search_key : T, arr_len : Nat) : Int {
        if (arr_len == 0) return -1; // should insert at index Int.abs(i + 1)
        var l = 0;

        // arr_len will always be between 4 and 512
        var r = arr_len - 1 : Nat;

        while (l < r) {
            let mid = (l + r) / 2;

            let ?val = arr[mid] else Debug.trap("1. binary_search: accessed a null value");

            switch (cmp(search_key, val)) {
                case (#less) {
                    r := mid;
                };
                case (#greater) {
                    l := mid + 1;
                };
                case (#equal) {
                    return mid;
                };
            };
        };

        let insertion = l;

        // Check if the insertion point is valid
        // return the insertion point but negative and subtracting 1 indicating that the key was not found
        // such that the insertion index for the key is Int.abs(insertion) - 1
        // [0,  1,  2]
        //  |   |   |
        // -1, -2, -3
        switch (arr[insertion]) {
            case (?val) {
                switch (cmp(search_key, val)) {
                    case (#equal) insertion;
                    case (#less) -(insertion + 1);
                    case (#greater) -(insertion + 2);
                };
            };
            case (_) Debug.trap("1. binary_search: accessed a null value");
        };

    };

    func adapt_cmp<K, V>(cmp : CmpFn<K>) : MultiCmpFn<K, (K, V)> {
        func(a : K, b : (K, V)) : Order {
            cmp(a, b.0);
        };
    };

    public func get_leaf_node<K, V>(self : BpTree<K, V>, cmp : CmpFn<K>, key : K) : Leaf<K, V> {
        var curr = ?self.root;

        loop {
            switch (curr) {
                case (? #branch(node)) {
                    let int_index = binary_search<K, K>(node.keys, cmp, key, node.count - 1);
                    let node_index = if (int_index >= 0) Int.abs(int_index) + 1 else Int.abs(int_index + 1);
                    // Debug.print("get_leaf branch index = " # debug_show (int_index, node_index));
                    // Debug.print("count " # debug_show node.count);
                    curr := node.children[node_index];
                };
                case (? #leaf(leaf_node)) {
                    return leaf_node;
                };
                case (_) Debug.trap("get_leaf_node: accessed a null value");
            };
        };
    };

    public func get_min_leaf_node<K, V>(self : BpTree<K, V>) : Leaf<K, V> {
        var node = ?self.root;

        loop {
            switch (node) {
                case (? #branch(branch)) {
                    node := branch.children[0];
                };
                case (? #leaf(leaf_node)) {
                    return leaf_node;
                };
                case (_) Debug.trap("get_min_leaf_node: accessed a null value");
            };
        };
    };

    public func get<K, V>(self : BpTree<K, V>, cmp : CmpFn<K>, key : K) : ?V {
        let leaf_node = get_leaf_node<K, V>(self, cmp, key);

        let i = binary_search<(K, V), K>(leaf_node.kvs, adapt_cmp(cmp), key, leaf_node.count);

        if (i >= 0) {
            let ?kv = leaf_node.kvs[Int.abs(i)] else Debug.trap("1. get: accessed a null value");
            return ?kv.1;
        };

        null;
    };

    func cmp_key<K, V>(cmp : CmpFn<K>) : CmpFn<(K, V)> {
        func(a : (K, V), b : (K, V)) : Order {
            cmp(a.0, b.0);
        };
    };

    func extract<T>(arr : [var ?T], index : Nat) : ?T {
        let tmp = arr[index];
        arr[index] := null;
        tmp;
    };

    public func toText<K, V>(self : BpTree<K, V>, key_to_text : (K) -> Text, val_to_text : (V) -> Text) : Text {
        var t = "BpTree { order: " # debug_show self.order # ", size: " # debug_show self.size # ", root: ";

        t #= switch (self.root) {
            case (#leaf(node)) "leaf { " # Leaf.toText<K, V>(node, key_to_text, val_to_text) # " }";
            case (#branch(node)) "branch {" # Branch.toText<K, V>(node, key_to_text, val_to_text) # "}";
        };

        t #= "}";

        t;
    };


    public func split_leaf<K, V>(leaf : Leaf<K, V>, elem_index : Nat, elem : (K, V)) : Leaf<K, V> {

        let arr_len = leaf.count;
        let median = (arr_len / 2) + 1;

        let is_elem_added_to_right = elem_index >= median;

        // if elem is added to the left
        // this variable allows us to retrieve the last element on the left
        // that gets shifted by the inserted elemeent
        var offset = if (is_elem_added_to_right) 0 else 1;

        var already_inserted = false;
        let right_kvs = Array.tabulateVar<?(K, V)>(
            leaf.kvs.size(),
            func(i : Nat) : ?(K, V) {

                let j = i + median - offset : Nat;

                if (j >= median and j == elem_index and not already_inserted) {
                    offset += 1;
                    already_inserted := true;
                    ?elem;
                } else if (j >= arr_len) {
                    null;
                } else {
                    extract(leaf.kvs, j);
                };
            },
        );

        var j = median - 1 : Nat;

        while (j > elem_index) {
            leaf.kvs[j] := leaf.kvs[j - 1];
            j -= 1;
        };

        if (j == elem_index) {
            leaf.kvs[j] := ?elem;
        };

        let right_node = Node.newLeaf<K, V>(leaf.kvs.size(), ?right_kvs);

        leaf.count := median;
        right_node.count := arr_len + 1 - median;

        right_node.index := leaf.index + 1;
        right_node.parent := leaf.parent;

        // update next pointers
        right_node.next := leaf.next;
        leaf.next := ?right_node;

        // if (not validate_array_equal_count(leaf.kvs, leaf.count)) {
        //     Debug.print("leaf.count = " # debug_show leaf.count);
        //     Debug.trap(
        //         "leaf.kvs = " # debug_show Array.map(
        //             Array.freeze(leaf.kvs),
        //             func(opt_kv : ?(K, V)) : Text {
        //                 switch (opt_kv) {
        //                     case (?kv) "1";
        //                     case (_) "0";
        //                 };
        //             },
        //         )
        //     );
        // };

        // if (not validate_array_equal_count(right_node.kvs, right_node.count)) {
        //     Debug.print("right_node.count = " # debug_show right_node.count);
        //     Debug.trap(
        //         "right_node.kvs = " # debug_show Array.map(
        //             Array.freeze(right_node.kvs),
        //             func(opt_kv : ?(K, V)) : Text {
        //                 switch (opt_kv) {
        //                     case (?kv) "1";
        //                     case (_) "0";
        //                 };
        //             },
        //         )
        //     );
        // };

        right_node;
    };

    public func split_branch<K, V>(node : Branch<K, V>, child : Node<K, V>, child_index : Nat, first_child_key : K) : Branch<K, V> {
        let arr_len = node.count;
        let median = (arr_len / 2) + 1;

        let is_elem_added_to_right = child_index >= median;

        var median_key = ?first_child_key;

        var offset = if (is_elem_added_to_right) 0 else 1;
        var already_inserted = false;

        let right = Branch.new<K, V>(node.children.size(), null);

        // for (i in Iter.range(0, node.children.size() - 1)) {
        //     let j = i + median - offset : Nat;

        //     if (j >= median and j == child_index and not already_inserted) {
        //         offset += 1;
        //         already_inserted := true;
        //         right.children[i] := ?child;
        //     } else if (j >= arr_len) {
        //         right.children[i] := null;
        //     } else {

        //         if (i == 0) {
        //             Debug.print("median_key at pos " # debug_show (j - 1: Nat));
        //             median_key := node.keys[j - 1];
        //         }else {
        //             right.keys[i - 1] := node.keys[j - 1];
        //         };
        //         right.children[i] := extract(node.children, j);
        //     };
        // };

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
                        // Debug.print("median_key at pos " # debug_show (j - 1 : Nat));
                        median_key := node.keys[j - 1];
                    } else {
                        // Debug.print("right keys size " # debug_show right_keys.size());
                        // Debug.print("right_keys at pos " # debug_show (i - 1 : Nat));

                        // Debug.print("node.keys size " # debug_show node.keys.size());
                        // Debug.print("node.keys at pos " # debug_show (j - 1 : Nat));

                        // Debug.print("arr_len " # debug_show arr_len);

                        right_keys[i - 1] := node.keys[j - 1];
                    };
                    node.keys[j - 1] := null;

                    extract(node.children, j);
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

       

        // Debug.print(
        //     "after rs node.children: " # debug_show Array.map(
        //         Array.freeze(node.children),
        //         func(opt_node : ?Node<K, V>) : Int {
        //             switch (opt_node) {
        //                 case ((? #branch(node) or ? #leaf(node)) : ?SharedNode<K, V>) node.index;
        //                 case (_) -1;
        //             };
        //         },
        //     )
        // );

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
            // Debug.print("(j, k) = " # debug_show (j, child_index));

            j -= 1;
        };

        // Debug.print(
        //     "after ms node.children: " # debug_show Array.map(
        //         Array.freeze(node.children),
        //         func(opt_node : ?Node<K, V>) : Int {
        //             switch (opt_node) {
        //                 case ((? #branch(node) or ? #leaf(node)) : ?SharedNode<K, V>) node.index;
        //                 case (_) -1;
        //             };
        //         },
        //     )
        // );

        // Debug.print("child_index = " # debug_show child_index);
        // Debug.print("j = " # debug_show j);

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

        // assert validate_indexes(node.children, node.count);
        // assert validate_array_equal_count(node.keys, node.count - 1 : Nat);
        // assert validate_array_equal_count(node.children, node.count);

        // assert validate_indexes(right_node.children, right_node.count);
        // assert validate_array_equal_count(right_node.keys, right_node.count - 1 : Nat);
        // assert validate_array_equal_count(right_node.children, right_node.count);

        // store the first key of the right node at the end of the keys in left node
        // no need to delete as the value will get overwritten because it exceeds the count position
        right_node.keys[right_node.keys.size() - 1] := median_key;

        right_node;
    };

    public func validate_array_equal_count<T>(arr : [var ?T], count : Nat) : Bool {
        var i = 0;

        for (opt_elem in arr.vals()) {
            let ?elem = opt_elem else return i == count;
            i += 1;
        };

        i == count;
    };

    public func validate_indexes<K, V>(arr : [var ?Node<K, V>], count : Nat) : Bool {

        var i = 0;

        while (i < count) {
            switch (arr[i] : ?SharedNode<K, V>) {
                case (? #branch(node) or ? #leaf(node)) {
                    if (node.index != i) return false;
                };
                case (_) Debug.trap("validate_indexes: accessed a null value");
            };
            i += 1;
        };

        true;
    };

    public func is_sorted<T>(arr: [var ?T], cmp: CmpFn<T>): Bool {
        var i = 0;

        while (i < ((arr.size() - 1) : Nat)) {
            let ?a = arr[i] else return true;
            let ?b = arr[i + 1] else return true;

            if (cmp(a, b) == #greater) return false;
            i += 1;
        };

        true;

    };

    public func indexes<K, V>(children : [var ?Node<K, V>]) : [Int] {
        Array.map<?Node<K, V>, Int>(
            Array.freeze(children),
            func(opt_node : ?Node<K, V>) : Int {
                switch (opt_node) {
                    case ((? #branch(node) or ? #leaf(node)) : ?SharedNode<K, V>) node.index;
                    case (_) -1;
                };
            },
        );
    };

    public func insert(self : BpTree<Nat, Nat>, cmp : CmpFn<Nat>, key : Nat, val : Nat) : ?Nat {

        let leaf_node = get_leaf_node<Nat, Nat>(self, cmp, key);

        let entry = (key, val);

        let int_elem_index = binary_search<(Nat, Nat), Nat>(leaf_node.kvs, adapt_cmp(cmp), key, leaf_node.count);
        let elem_index = if (int_elem_index >= 0) Int.abs(int_elem_index) else Int.abs(int_elem_index + 1);

        let prev_value = if (int_elem_index >= 0) {
            let ?kv = leaf_node.kvs[elem_index] else Debug.trap("1. insert: accessed a null value while replacing a key-value pair");
            leaf_node.kvs[elem_index] := ?entry;
            return ?kv.1;
        } else {
            null;
        };

        if (leaf_node.count < self.order) {
            // shift elems to the right and insert the new key-value pair
            var j = leaf_node.count;

            while (j > elem_index) {
                leaf_node.kvs[j] := leaf_node.kvs[j - 1];
                j -= 1;
            };

            leaf_node.kvs[elem_index] := ?entry;
            leaf_node.count += 1;

            self.size += 1;
            return prev_value;
        };

        // split leaf node
        let right_leaf_node = split_leaf(leaf_node, elem_index, entry);

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
            let ?parent = opt_parent else Debug.trap("3. insert: accessed a null parent value");

            if (parent.count < self.order) {
                // shift elems to the right and insert the new key-value pair
                var j = parent.count;
                // Debug.print("parent count " # debug_show parent.count);
                // Debug.print("parent keys before = " # debug_show Array.freeze(parent.keys));
                // Debug.print("right index = " # debug_show right_index);

                while (j >= right_index) {
                    if (j == right_index) {
                        parent.keys[j - 1] := ?right_key;
                        parent.children[j] := ?right_node;
                    } else {
                        parent.keys[j - 1] := parent.keys[j - 2];
                        parent.children[j] := parent.children[j - 1];
                    };

                    switch (parent.children[j]) {
                        case ((? #branch(node) or ? #leaf(node)) : ?SharedNode<Nat, Nat>) {

                            node.index := j;
                        };
                        case (_) {};
                    };

                    j -= 1;
                };

                // Debug.print("parent keys after = " # debug_show Array.freeze(parent.keys));


                parent.count += 1;

                // Debug.print("parent.keys: " # debug_show Array.map(
                //     Array.freeze(parent.keys),
                //     func (opt_key : ?Nat) : Text {
                //         switch(opt_key) {
                //             case (?key) "1";
                //             case (_) "0";
                //         };
                //     }
                // ));

                // assert validate_indexes(parent.children, parent.count);
                // assert validate_array_equal_count(parent.keys, parent.count - 1 : Nat);
                // assert validate_array_equal_count(parent.children, parent.count);

                self.size += 1;
                return prev_value;

            } else {
                // Debug.print("size of b-plus-tree = " # debug_show self.size);
                // Debug.print("insert: parent node is full");

                let median = (parent.count / 2) + 1; // include inserted key-value pair
                let split_node = split_branch(parent, right_node, right_index, right_key);

                // Debug.print("left keys = " # debug_show Array.freeze(parent.keys));
                // Debug.print("right keys = " # debug_show Array.freeze(split_node.keys));

                // Debug.print(
                //     "parent.children: " # debug_show Array.map(
                //         Array.freeze(parent.children),
                //         func(opt_node : ?Node<Nat, Nat>) : Int {
                //             switch (opt_node) {
                //                 case ((? #branch(node) or ? #leaf(node)) : ?SharedNode<Nat, Nat>) node.index;
                //                 case (_) -1;
                //             };
                //         },
                //     )
                // );

                // Debug.print("count: " # debug_show parent.count);

                let ?first_key = extract(split_node.keys, split_node.keys.size() - 1 : Nat) else Debug.trap("4. insert: accessed a null value in first key of branch");
                right_key := first_key;
                // Debug.print("returned right_key " # debug_show right_key);
                // assert validate_indexes(parent.children, parent.count);
                // assert is_sorted<Nat>(parent.keys, cmp);
                // assert validate_array_equal_count(parent.keys, parent.count - 1 : Nat);
                // assert validate_array_equal_count(parent.children, parent.count);

                // assert validate_indexes(split_node.children, split_node.count);
                // assert is_sorted<Nat>(split_node.keys, cmp);
                // assert validate_array_equal_count(split_node.keys, split_node.count - 1 : Nat);
                // assert validate_array_equal_count(split_node.children, split_node.count);
 
                left_node := #branch(parent);
                right_node := #branch(split_node);

                right_index := split_node.index;
                opt_parent := split_node.parent;
            };
        };

        // create new root node
        // let keys = Array.init<?Nat>(self.order - 1, null);
        // keys[0] := ?right_key;

        let children = Array.init<?Node<Nat, Nat>>(self.order, null);
        children[0] := ?left_node;
        children[1] := ?right_node;

        let root_node = Branch.new<Nat, Nat>(self.order, ?children);
        root_node.keys[0] := ?right_key;
        assert root_node.count == 2;

        self.root := #branch(root_node);
        // assert validate_indexes(root_node.children, root_node.count);
        // assert validate_array_equal_count(root_node.keys, root_node.count - 1 : Nat);
        // assert validate_array_equal_count(root_node.children, root_node.count);

        self.size += 1;
        prev_value;

    };

    public func min<K, V>(self : BpTree<K, V>) : ?(K, V) {
        let leaf_node = get_min_leaf_node(self) else return null;
        leaf_node.kvs[0];
    };

    public func max<K, V>(self : BpTree<K, V>) : ?(K, V) {
        let leaf_node = get_min_leaf_node(self) else return null;
        leaf_node.kvs[leaf_node.count - 1];
    };

    public func toArray<K, V>(self : BpTree<K, V>) : [(K, V)] {
        var node = ?self.root;
        let buffer = Buffer.Buffer<(K, V)>(self.size);

        var leaf_node : ?Leaf<K, V> = ?get_min_leaf_node(self);

        label _loop loop {
            switch (leaf_node) {
                case (?leaf) {
                    label _for_loop for (opt in leaf.kvs.vals()) {
                        let ?kv = opt else break _for_loop;
                        buffer.add(kv);
                    };

                    leaf_node := leaf.next;
                };
                case (_) break _loop;
            };
        };

        Buffer.toArray(buffer);
    };

    public func entries<K, V>(self : BpTree<K, V>) : Iter<(K, V)> {
        var node = ?get_min_leaf_node(self);
        var i = 0;

        object {
            public func next() : ?(K, V) {
                switch (node) {
                    case (?leaf) {
                        if (i >= leaf.count) {
                            node := leaf.next;
                            i := 0;
                            return next();
                        };

                        let entry = leaf.kvs[i];
                        i += 1;
                        entry;
                    };
                    case (_) null;
                };
            };
        };
    };

    public func keys<K, V>(self : BpTree<K, V>) : Iter<K> {
        Iter.map(
            entries(self),
            func(kv : (K, V)) : K {
                kv.0;
            },
        );
    };

    public func vals<K, V>(self : BpTree<K, V>) : Iter<V> {
        Iter.map(
            entries(self),
            func(kv : (K, V)) : V {
                kv.1;
            },
        );
    };

    public func toLeafNodes<K, V>(self : BpTree<K, V>) : [[?(K, V)]] {
        var node = ?self.root;
        let buffer = Buffer.Buffer<[?(K, V)]>(self.size);

        var leaf_node : ?Leaf<K, V> = ?get_min_leaf_node(self);

        label _loop loop {
            switch (leaf_node) {
                case (?leaf) {
                    // let leaf_buffer = Buffer.Buffer<(K, V)>(leaf.count);

                    // label _for_loop for (opt in leaf.kvs.vals()) {
                    //     let ?kv = opt else break _for_loop;
                    //     leaf_buffer.add(kv);
                    // };

                    buffer.add(Array.freeze<?(K, V)>(leaf.kvs));

                    leaf_node := leaf.next;
                };
                case (_) break _loop;
            };
        };

        Buffer.toArray(buffer);
    };

    public func toNodeKeys<K, V>(self : BpTree<K, V>) : [[(Nat, [?K])]] {
        var nodes = Deque.fromArray<?Node<K, V>>([?self.root]);
        let buffer = Buffer.Buffer<[(Nat, [?K])]>(self.size / 2);

        while (nodes.size() > 0) {
            let row = Buffer.Buffer<(Nat, [?K])>(nodes.size());

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

                        row.add((node.index, Buffer.toArray(node_buffer)));
                    };
                    case (_) {};
                };
            };

            buffer.add(Buffer.toArray(row));
        };

        Buffer.toArray(buffer);
    };

};
