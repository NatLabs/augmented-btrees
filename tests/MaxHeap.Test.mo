import { test; suite } "mo:test";

import MaxHeap "../src/internal/MaxHeap";
import Cmp "../src/Cmp";
import Fuzz "mo:fuzz";

import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Int "mo:base/Int";
import Buffer "mo:base/Buffer";

import Itertools "mo:itertools/Iter";

let fuzz = Fuzz.fromSeed(0x7f3a3e7e);

suite(
    "MaxHeap",
    func() {
        test(
            "put()",
            func() {
                let heap = MaxHeap.new<Nat>(10);

                var expected : ?Nat = null;

                for (heap_count in Iter.range(0, 9)) {
                    let val = fuzz.nat.randomRange(1, 10_000);

                    switch (expected) {
                        case (?max) if (Cmp.Nat(val, max) == 1) expected := ?val;
                        case (null) expected := ?val;
                    };

                    MaxHeap.put(heap, Cmp.Nat, val, heap_count);
                    let received = MaxHeap.peekMax(heap);

                    assert expected == received;
                };
            },
        );

        test(
            "removeMax()",
            func() {
                let arr = [9, 1, 8, 2, 7, 3, 6, 4, 5];

                let heap = MaxHeap.fromArray(arr, Cmp.Nat);
                let sorted_arr = Array.sort(arr, Nat.compare);

                for (i in Iter.range(0, arr.size() - 1)) {
                    let sorted_index = arr.size() - i - 1;
                    let count = arr.size() - i;

                    let expected = ?sorted_arr[sorted_index];
                    let received = MaxHeap.removeMax(heap, Cmp.Nat, count);

                    assert expected == received;
                };

            },
        );

        test(
            "removeIf()",
            func() {
                let arr = [9, 1, 8, 2, 7, 3, 6, 4, 5];

                let heap_size = arr.size();
                let heap = MaxHeap.fromArray(arr, Cmp.Nat);

                func remove_odd_nums(val: Nat): Bool {
                    return val % 2 == 1;
                };
                
                var new_heap_size : Int = MaxHeap.removeIf<Nat>(heap, Cmp.Nat, heap_size, remove_odd_nums);
                assert new_heap_size == 4;

                let max_iter = {
                    next = func(): ?Nat {
                        let max = MaxHeap.removeMax(heap, Cmp.Nat, Int.abs(new_heap_size));
                        new_heap_size -= 1;
                        return max;
                    }
                };
                
                for ((a, b) in Itertools.zip(max_iter, [8, 6, 4, 2].vals())){
                    assert a == b;
                };

            },
        );

        test("remove()", func (){
            let arr = [9, 1, 8, 2, 7, 3, 6, 4, 5];
            let sorted = Buffer.fromArray<Nat>(arr);
            sorted.sort(Nat.compare);

            let heap = MaxHeap.fromArray(arr, Cmp.Nat);

            var i = 0;

            while (i < arr.size()){
                assert MaxHeap.peekMax(heap) == sorted.getOpt(sorted.size() - 1);

                let to_remove = arr[i];
                assert ?to_remove == MaxHeap.remove(heap, Cmp.Nat, arr.size() - i, to_remove);
                
                let ?sorted_index = Buffer.indexOf<Nat>(to_remove, sorted, Nat.equal) else Debug.trap("remove: sorted_index is null"); 
                ignore sorted.remove(sorted_index);

                i += 1;
            };

            assert MaxHeap.peekMax(heap) == null;
        });

        test("replace()", func (){
            let arr = [9, 1, 8, 2, 7, 3, 6, 4, 5];
            let sorted = Buffer.fromArray<Nat>(arr);
            sorted.sort(Nat.compare);

            let heap = MaxHeap.fromArray(arr, Cmp.Nat);

            var i = 0;

            while (i < arr.size()){
                assert MaxHeap.peekMax(heap) == sorted.getOpt(sorted.size() - 1);

                let to_remove = arr[i];
                assert ?to_remove == MaxHeap.remove(heap, Cmp.Nat, arr.size() - i, to_remove);
                
                let ?sorted_index = Buffer.indexOf<Nat>(to_remove, sorted, Nat.equal) else Debug.trap("remove: sorted_index is null"); 
                ignore sorted.remove(sorted_index);

                i += 1;
            };
            
            assert MaxHeap.peekMax(heap) == null;
        });
    },
);
