import Debug "mo:base/Debug";
module {
    public func unwrap<T>(optional: ?T, trap_msg: Text) : T {
        switch(optional) {
            case (?v) return v;
            case (_) return Debug.trap(trap_msg);
        };
    }
}