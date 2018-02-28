package hscript.plus;

import massive.munit.Assert;

class ScriptStateTest {
    var state:ScriptState;
    var script(default, set):String;
    var scriptReturn:Dynamic;

    function set_script(newScript:String) {
        script = newScript;
        scriptReturn = state.executeString(newScript);
        return newScript;
    }    

    public function new() {}

    @Before
    public function setup() {
        state = new ScriptState();
        state.set("pass", false);
        #if (flash || js)
        state.getFileContent = path -> haxe.Resource.getString(path);
        state.getScriptPaths = haxe.Resource.listNames;
        #end
    }

    @Test
    public function testReadmeUsageExample() {
        var script = "
        class TestObject {
            public static function main() {
                var object = new TestObject(10, 10);
                object.name = NAME;
                Assert.areEqual('Ball', object.name);
            }
            
            public var x:Float = 0;
            public var y:Float = 0;

            public function new(x:Float, y:Float) {
                this.x = x;
                this.y = y;
            }
        }
        ";
        state.set("Assert", Assert);
        state.set("NAME", "Ball"); // set a global variable
        state.executeString(script); // executes a String
		
        // get a global variable
        var TestObject = state.get("TestObject"); // get a global variable
        TestObject.main();
    }

    @Test
    public function testClassCreated() {
        script = '
        class ClassCreated {
            public static function main() {
                return new ClassCreated(10);
            }

            public var mass:Float = 0;

            public function new(mass)
                this.mass = mass;
        }
        ';
        var object = scriptReturn;
        Assert.areEqual(10, object.mass);
    }

    @Test
    public function testExecuteFile() {
        state.executeFile("scripts/Script.hx");
        assertPass();
    }
    
    @Test
    public function testMainFunctionAutoCalled() {
        script = "
        class MainFunctionAutoCalled {
            public static function main() {
                pass = true;
            }
        }
        ";
        
        assertPass();
    }

    @Test
    public function testImportOtherScript() {
        state.scriptDirectory = "scripts/";
        script = "
        import Script;

        new Script();
        ";
        
        assertPass();
    }

    function assertPass() {
        Assert.isTrue(state.get("pass"));
    }
}