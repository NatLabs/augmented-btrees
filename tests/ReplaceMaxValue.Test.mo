import Debug "mo:base/Debug";
import Nat "mo:base/Nat";
import Iter "mo:base/Iter";
import Buffer "mo:base/Buffer";
import Int "mo:base/Int";

import { test; suite } "mo:test";
import Fuzz "mo:fuzz";

import { MaxBpTree; Cmp } "../src";
import MaxBpTreeMethods "../src/MaxBpTree/Methods";
import T "../src/MaxBpTree/Types";

let { Const = C } = T;

func validate_max_path(tree : MaxBpTree.MaxBpTree<Nat, Nat>) : Bool {
    MaxBpTreeMethods.validate_max_path(tree, Cmp.Nat);
};

func validate_max_values(tree : MaxBpTree.MaxBpTree<Nat, Nat>) : Bool {
    MaxBpTreeMethods.validate_max_values(tree, Cmp.Nat);
};

/// Asserts that maxValue() and replaceMaxValue() agree on which entry is the max.
/// Replaces with the same value so the tree state is unchanged.
func assert_max_consistent(tree : MaxBpTree.MaxBpTree<Nat, Nat>, msg : Text) {
    let ?max_from_root = MaxBpTree.maxValue(tree) else Debug.trap(msg # ": tree is empty");

    // replaceMaxValue with the same value — should return the same entry
    let ?replaced = MaxBpTree.replaceMaxValue(tree, Cmp.Nat, Cmp.Nat, max_from_root.1) else Debug.trap(msg # ": replaceMaxValue returned null");

    if (replaced.0 != max_from_root.0 or replaced.1 != max_from_root.1) {
        Debug.print(msg # ": MISMATCH!");
        Debug.print("  maxValue()        = " # debug_show max_from_root);
        Debug.print("  replaceMaxValue() = " # debug_show replaced);
        Debug.print("  tree size = " # debug_show MaxBpTree.size(tree));
        assert false;
    };
};

suite(
    "replaceMaxValue consistency",
    func() {

        test(
            "fuzz: multi-seed replaceMaxValue consistency",
            func() {
                let seeds : [Nat] = [
                    0xdeadbeef, 0xcafebabe, 0x12345678,
                ];

                for (order in [4, 8, 16, 32].vals()) {
                    let prefill_fuzz = Fuzz.fromSeed(0xdeadbeef);
                    let tree = MaxBpTree.new<Nat, Nat>(?order);
                    let base_keys = Buffer.Buffer<Nat>(6_000);

                    // Pre-fill with 6_000 entries once per order
                    var k_cursor : Nat = 0;
                    while (k_cursor < 6_000) {
                        let v = prefill_fuzz.nat.randomRange(1, 50_000);
                        ignore MaxBpTree.insert(tree, Cmp.Nat, Cmp.Nat, k_cursor, v);
                        base_keys.add(k_cursor);
                        k_cursor += 1;
                    };

                    assert MaxBpTree.size(tree) == 6_000;
                    if (not validate_max_values(tree)) {
                        Debug.print("VALIDATION FAILED after prefill order=" # debug_show order);
                        assert false;
                    };

                    for (seed in seeds.vals()) {
                        let fuzz_gen = Fuzz.fromSeed(seed);

                        // Track keys added/removed during this seed's mutations
                        let keys = Buffer.Buffer<Nat>(base_keys.size() + 6_000);
                        for (k in base_keys.vals()) { keys.add(k) };

                        var i = 0;
                        while (i < 6_000) {
                            let action = fuzz_gen.nat.randomRange(0, 2);

                            if (action == 0 or keys.size() == 0) {
                                let k = fuzz_gen.nat.randomRange(6_000, 60_000);
                                let v = fuzz_gen.nat.randomRange(1, 50_000);
                                let prev = MaxBpTree.insert(tree, Cmp.Nat, Cmp.Nat, k, v);
                                if (prev == null) keys.add(k);
                            } else if (action == 1 and keys.size() > 0) {
                                let idx = if (keys.size() == 1) { 0 } else { fuzz_gen.nat.randomRange(0, keys.size() - 1) };
                                let k = keys.get(idx);
                                ignore MaxBpTree.remove(tree, Cmp.Nat, Cmp.Nat, k);
                                ignore keys.remove(idx);
                            } else {
                                if (MaxBpTree.size(tree) > 0) {
                                    let ?max_val = MaxBpTree.maxValue(tree) else Debug.trap("empty");
                                    let new_val = if (max_val.1 > 1) {
                                        if (max_val.1 == 2) { 1 } else {
                                            fuzz_gen.nat.randomRange(1, max_val.1 - 1);
                                        };
                                    } else { 1 };
                                    let ?replaced = MaxBpTree.replaceMaxValue(tree, Cmp.Nat, Cmp.Nat, new_val) else Debug.trap("null");

                                    if (replaced.1 != max_val.1) {
                                        Debug.print("MISMATCH at seed=" # debug_show seed # " order=" # debug_show order # " iter=" # debug_show i);
                                        Debug.print("  maxValue()        = " # debug_show max_val);
                                        Debug.print("  replaceMaxValue() = " # debug_show replaced);
                                        assert false;
                                    };
                                };
                            };

                            // Validate every 300 iterations
                            if (i % 300 == 0 and MaxBpTree.size(tree) > 0) {
                                if (not validate_max_values(tree)) {
                                    Debug.print("VALIDATION FAILED at seed=" # debug_show seed # " order=" # debug_show order # " iter=" # debug_show i);
                                    assert false;
                                };
                            };

                            i += 1;
                        };

                        // Final validation after all mutations for this seed
                        if (MaxBpTree.size(tree) > 0) {
                            if (not validate_max_values(tree)) {
                                Debug.print("FINAL VALIDATION FAILED at seed=" # debug_show seed # " order=" # debug_show order);
                                assert false;
                            };
                        };
                    };
                };
            },
        );
    },
);
