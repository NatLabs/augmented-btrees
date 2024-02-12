import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Int "mo:base/Int";

import T "Types";

module {

    public func shift_by<A>(arr : [var ?A], start : Nat, end : Nat, shift : Int) {
        if (shift == 0) return;

        if (shift > 0) {
            var i = end; // exclusive
            while (i > start) {
                arr[Int.abs(shift + i - 1)] := arr[i - 1];
                arr[i - 1] := null;
                i -= 1;
            };
            return;
        };

        var i = start;
        while (i < end) {
            arr[Int.abs(shift + i)] := arr[i];
            arr[i] := null;
            i += 1;
        };

    };

    public func insert<A>(arr : [var ?A], index : Nat, item : ?A, size : Nat) {
        var i = size;
        while (i > index) {
            arr[i] := arr[i - 1];
            i -= 1;
        };

        arr[index] := item;
    };

    public func remove<A>(arr : [var ?A], index : Nat, size : Nat) : ?A {
        if (size == 0) return null;

        var i = index;
        let item = arr[i];

        while (i < (size - 1 : Nat)) {
            arr[i] := arr[i + 1];
            i += 1;
        };

        arr[i] := null;

        item;
    };

    // public func linear_search<B, A>(arr : [var ?A], cmp : T.MultiCmpFn<B, A>, search_key : B, arr_len : Nat) : Int {
    //     var i = 0;

    //     while (i < arr_len) {
    //         let ?val = arr[i] else Debug.trap("linear_search: accessed a null value");
    //         switch (cmp(search_key, val)) {
    //             case (0) return i;
    //             case (-1) return -(i + 1);
    //             case (+1) i += 1;
    //         };
    //     };

    //     return -(i + 1);
    // };

    public func binary_search<B, A>(arr : [var ?A], cmp : T.MultiCmpFn<B, A>, search_key : B, arr_len : Nat) : Int {
        if (arr_len == 0) return -1; // should insert at index Int.abs(i + 1)
        var l = 0;

        // arr_len will always be between 4 and 512
        var r = arr_len - 1 : Nat;

        while (l < r) {
            let mid = (l + r) / 2;

            let ?val = arr[mid] else Debug.trap("1. binary_search: accessed a null value");

            let result = cmp(search_key, val);
            if (result == -1) {
                r := mid;

            } else if (result == 1) {
                l := mid + 1;
            } else {
                return mid;
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
                let result = cmp(search_key, val);

                if (result == 0) insertion
                else if (result == -1) -(insertion + 1)
                else  -(insertion + 2);
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
};
