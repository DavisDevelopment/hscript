package hscript.plus;

import massive.munit.Assert;
import hscript.plus.core.DynamicFun;

class InterpPlusTest extends TestScriptState {
	@Test
	public function testCreateNormalObject() {
		script = "
		import Sprite;
		new Sprite()";
		Assert.isType(scriptReturn, Sprite);
	}

	@Test
	public function testNotNull() {
		script = 'class Object {}';

		Assert.isNotNull(get("Object"));
	}

	@Test
	public function testVariable() {
		script = '
		class Object {
			var mass:physics.Mass = 10;
		}
		';

		var object = scriptReturn;
		Assert.areEqual(10, object.mass);
	}

	@Test
	public function testFunction() {
		script = '
		public function main()
			pass = true;';

		var main = scriptReturn;
		main();
	}

	@Test
	public function testImport() {
		set("Assert", null);

		script = '
		import massive.munit.Assert;
		Assert.isTrue(true);
		';
	}

	@Test
	public function testSetGlobalField() {
		script = '
		class SetGlobalField {
			public static function set()
				pass = true;
		}

		SetGlobalField.set();
		';
		Assert.isTrue(pass);
	}

	@Test
	public function testNew() {
		script = '
		class New {
			var num:Int = 50;
			public function new() {
				pass = true;
			}
		}

		new New().num;
		';
		Assert.areEqual(50, scriptReturn);
	}

	@Test
	public function testThis() {
		script = '
		class Object {
			var mass:Float = 0;
			public function new(mass:Float) {
				this.mass = mass;
			}
		}
		';

		var mass = 20;
		var Object = scriptReturn;
		var object = DynamicFun.create(interp, "", Object, null, [mass]);
		Assert.areEqual(mass, object.mass);
	}

	@Test
	public function testStaticFunctionWithVarDeclareNoError() {
		script = "
		class StatFuncVarDecNoEr {
            public static function main() {
                var x = 10;
            }
    	}

		main();
		";
	}

	@Test
	public function testVariableDeclaredWithoutValueNoError() {
		script = "
		class VarDecWitValNoEr {
			var sprite;
    	}
		";
	}

	@Test
	
	public function testWithoutThis() {
		script = '
		class WithoutThis {
			var x:Int = -1;
			public function new() {
				x = 0;
			}
		}
		';
		var object = DynamicFun.create(interp, "", scriptReturn);
		Assert.areEqual(0, object.x);
	}

	@Test
	public function testMultipleClassNoError() {
		script = '
		class Entity {}
		class Player {}
		';
	}

	@Test
	public function testFunctionReturnValue() {
		script = '
		class FunctionReturnValue {
			public static function getNum() {
				return 10;
			}
		}

		FunctionReturnValue.getNum();
		';
		Assert.areEqual(10, scriptReturn);
	}

	@Test
	public function testInheritance() {
		script = "
		class GameObject {
			public var exists:Bool = true;

			public function destroy() {
				exists = false;
			}
		}

		class PhysicalObject extends GameObject {}
		
		object = new PhysicalObject();
		object.destroy();
		";

		var object = get("object");
		Assert.isFalse(object.exists);
	}

	@Test
	public function testMultipleInheritance() {
		script = "
		class GameObject {
			public var exists:Bool = true;

			public function destroy() {
				exists = false;
			}
		}

		class PhysicalObject extends GameObject {
			public var mass:Float = 1;

			public function setMass(newMass:Float) {
				mass = newMass;
			}
		}

		class SpriteObject extends PhysicalObject {}

		sprite = new SpriteObject();
		sprite.setMass(25);
		sprite.destroy();
		";

		var sprite = get("sprite");
		Assert.areEqual(25, sprite.mass);
		Assert.isFalse(sprite.exists);
	}
}