import Debug "mo:base/Debug";
import T "Types";

module {
    public func unwrap<T>(optional: ?T, trap_msg: Text) : T {
        switch(optional) {
            case (?v) return v;
            case (_) return Debug.trap(trap_msg);
        };
    };

    public func extract<T>(arr : [var ?T], index : Nat) : ?T {
        let tmp = arr[index];
        arr[index] := null;
        tmp;
    };

    public type SharedNodeFields<K, V> = {
        var count : Nat;
        var index : Nat;
        var parent : ?SharedNodeFields<K, V>;
    };

    public type SharedNode<K, V> = {
        #leaf : SharedNodeFields<K, V>;
        #branch : SharedNodeFields<K, V>;
    };

    public func validate_array_equal_count<T>(arr : [var ?T], count : Nat) : Bool {
        var i = 0;

        for (opt_elem in arr.vals()) {
            let ?elem = opt_elem else return i == count;
            i += 1;
        };

        i == count;
    };

    public func validate_indexes<K, V>(arr : [var ?SharedNode<K, V>], count : Nat) : Bool {

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
}