package hscript.plus.core;

import massive.munit.Assert;
class DynamicCreatorTest {
    public static inline var NAME = "Entity";

    public static var create = DynamicCreator.create;
    
    var interp:InterpPlus;
    var Entity:Dynamic;
    var Point:Dynamic;
    var Player:Dynamic;

    public function new() {}

    @BeforeClass
    public function setupClass() {
        interp = new InterpPlus();
    }
    
    @Before
    public function setup() {
        Entity = create(interp, NAME, null, { id:-1 });
        Reflect.setField(Entity, "new", () -> Entity.id = 0);
        Point = create(interp, "Point", Entity, { x:0, y:0 });
    }

    @Test
    public function testName() {
        Assert.areEqual(NAME, Entity.__sname__);
        Assert.areEqual("Point", Point.__sname__);
    }

    @Test
    public function testSuper() {
       Assert.areEqual(Entity, Point.super);
    }

    @Test
    
    public function testConstructorCalled() {
        Assert.areEqual(0, Entity.id);            
    }
}