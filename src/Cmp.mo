module Cmp {
    public func Nat(a: Nat, b: Nat) : Int8 {
        if (a < b) {
            -1;
        } else if (a > b) {
            1;
        } else {
            0;
        };
    };
}