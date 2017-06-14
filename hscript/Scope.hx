package hscript;

import hscript.ts.HSObject;

@:forward
abstract Scope (HSObject) {
    public inline function new():Void {
        this = new HSObject();
    }

    @:arrayAccess
    public inline function get(k:String):Dynamic return this.get(k);
    @:arrayAccess
    public inline function set(k:String, v:Dynamic):Dynamic return this.set(k, v);
}
