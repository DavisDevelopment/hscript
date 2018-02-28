package hscript.plus.core;

import massive.munit.Assert;

class InterpResolveTest extends TestScriptState {
    static var ID = 32;
    static var n = 110;
    var Entity:Dynamic;

    @Before
    override public function setup() {
        super.setup();
        
        Entity = { id:ID };
        set("this", Entity);
        set("n", n);
    }

    @Test
    public function testNonDynamic() {
        script = "n";
        Assert.areEqual(n, scriptReturn);
    }

    @Test
    public function testDynamic() {
        script = "id";
        Assert.areEqual(ID, scriptReturn);
    }

    @Test
    public function testNonExistent() {
        script = "nah";
        Assert.isNull(scriptReturn);
    }

    @Test
    public function testThisNotExists() {
        set("this", null);
        script = "id";
        Assert.isNull(scriptReturn);
    }
}