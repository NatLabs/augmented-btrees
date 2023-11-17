module {
    public func insert<A>(arr: [var ?A], index: Nat, item: ?A, size: Nat) {
        var i = size;
        while (i > index) {
            arr[i] := arr[i - 1];
            i -= 1;
        };

        arr[index] := item;
    };

    public func remove<A>(arr: [var ?A], index: Nat, size: Nat) : ?A {
        var i = index;
        let item = arr[i];

        while (i < (size - 1 : Nat)) {
            arr[i] := arr[i + 1];
            i += 1;
        };

        arr[i] := null;

        item;
    };
}