package hscript.plus.core;

import massive.munit.Assert;

class InterpGetTest extends TestScriptState {
    static var ID = 32;
    var Entity:Dynamic;

    @Before
    override public function setup() {
        super.setup();
        Entity = DynamicFun.create(interp, "Entity", null, { id: ID});
        set("Entity", Entity);
        set("this", Entity);
    }

    @Test
    public function testDynamicField() {
        script = "Entity.id";
        Assert.areEqual(ID, scriptReturn);
    }

    @Test
    public function testDynamicThis() {
        script = "this.id";
        Assert.areEqual(ID, scriptReturn);
    }

    @Test
    public function testNonDynamic() {
        set("Math", Math);
        script = "Math.PI";
        Assert.areEqual(Math.PI, scriptReturn);
    }
}