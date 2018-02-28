package hscript.plus.core;

import massive.munit.Assert;
class InterpEClassTest extends TestScriptState {
    var Entity:Dynamic;

    override function execute(e:Expr) {
        return scriptReturn = InterpEClass.expr(interp, e);
    }

    @:access(hscript.plus.InterpPlus)
    @Before
    override public function setup() {
        super.setup();
        interp.depth = 0;
        script = "
        class Entity {
            var id:Int = 0;

            public function new() {
                return 0;
            }

            public function normal() {
                return 1;
            }
        }
        ";
        Entity = get("Entity");
    }

    @Test
    public function testName() {
        Assert.areEqual("Entity", Entity.__sname__);
    }

    @Test
    public function testFunctions() {
        var constructor = Reflect.field(Entity, "new");

        Assert.isNotNull(constructor);
        Assert.isNotNull(Entity.normal);

        Assert.areEqual(0, constructor());
        Assert.areEqual(1, Reflect.field(Entity, "normal")());
    }

    @Test
    public function testVars() {
        Assert.areEqual(0, Entity.id);
    }

    @Test
    public function testNonEClass() {
        var value = InterpEClass.expr(interp, Expr.EIdent("nah"));
        Assert.isNull(value);
    }

    @Test
    public function testSuperClass() {
        script = "class Player extends Entity {}";
        var Player = get("Player");
        Assert.areEqual(Entity, Player.super);
    }
}