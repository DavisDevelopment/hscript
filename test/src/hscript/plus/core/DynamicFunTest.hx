package hscript.plus.core;

import massive.munit.Assert;

@:access(hscript.plus.DynamicFun)
class DynamicFunTest {
    public function new() {}

    @Test
	public function testIsDynamicObject() {
        Assert.isTrue(DynamicFun.isDynamicObject({ super:null }));
		Assert.isFalse(DynamicFun.isDynamicObject(Math));
        Assert.isFalse(DynamicFun.isDynamicObject(null));
	}

    @Test
    public function testGetFirstInHierarchy() {
        var s0 = { id:64 };
        var s1 = { super:s0, pos:[10, 20] };
        var s2 = { super:s1 };

        var pos = DynamicFun.getFirstInHierachy(s2, "pos");
        Assert.areEqual(s1.pos, pos);

        var id = DynamicFun.getFirstInHierachy(s2, "id");
        Assert.areEqual(s0.id, id);
    }

    @Test
    public function testIsHaxeClassName() {
        Assert.isTrue(DynamicFun.isHaxeClassName("Math"));
        Assert.isFalse(DynamicFun.isHaxeClassName("ClassNotExists"));
    }
}