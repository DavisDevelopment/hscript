package hscript;

import hscript.ts.HSObject;

@:forward
abstract Scope (HSObject) {
    public inline function new():Void {
        this = new HSObject();
    }

    public inline function define<T>(name:String, ?value:T, ?getter:Void->T, ?setter:T->T):Void {
        if (value == null) {
            if (getter != null) {
                this.defineProperty(name, {
                    get: getter,
                    set: setter
                });
            }
        }
        else {
            set(name, value);
        }
    }

    @:arrayAccess
    public inline function get(k:String):Dynamic return this.get(k);

    @:arrayAccess
    public inline function set(k:String, v:Dynamic):Dynamic return this.set(k, v);
}
