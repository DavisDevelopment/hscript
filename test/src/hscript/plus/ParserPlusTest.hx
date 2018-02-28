package hscript.plus;

import massive.munit.Assert;
import hscript.Expr;

@:access(hscript.plus.ParserPlus.expr)
class ParserPlusTest {
	var parser:ParserPlus;
	var script(default, set):String;
	var ast:Expr;

	function set_script(newScript:String) {
		ast = parser.parseString(newScript);
		return script = newScript;
	}

	public function new() {}

	@Before
	public function setup() {
		parser = new ParserPlus();
	}

	inline function getExpr(?expr:Expr):Expr {
		expr = expr == null ? ast : expr;
		return parser.expr(expr);
	}

	@Test
	public function testClassName() {
		script = 'class Sprite {}';
		
		switch (getExpr()) {
			case EClass(name, _, _):
				Assert.areEqual("Sprite", name);
			default:
		}
	}

	@Test
	public function testBaseClassName() {
		script = 'class Sprite extends Object {}';

		switch (getExpr()) {
			case EClass(_, _, baseClass):
				Assert.areEqual("Object", baseClass);
			default:
		}
	}

	@Test
	public function testClassBodyIsABlock() {
		script = 'class Box {
			var mass:Float = 10;
			function new(this) {}
		}';
		
		switch (getExpr()) {
			case EClass(_, e, _):
				switch (getExpr(e)) {
					case EBlock(_):
					default: Assert.fail('Expected EBlock but was [$e]');
				}
			default:
		}
	}

	@Test
	public function testAccessModifiers() {
		script = 'public inline static function build() {}';
		
		var contains = (what:Dynamic, array:Array<Dynamic>) ->
			if (array.indexOf(what) == -1) {
				Assert.assertionCount++;
				Assert.fail('Array does not contain [$what]');
			}

		switch (getExpr()) {
			case EFunction(_, _, _, _, access):
				contains(APublic, access);
				contains(AInline, access);
				contains(AStatic, access);
			default:
		}
	}

	@Test
	public function testPackage() {
		script = 'package;';
		packageNameIs("");

		script = 'package test;';
		packageNameIs("test");	

		script = 'package test.hscript.plus;';
		packageNameIs("test.hscript.plus");
	}

	inline function packageNameIs(name:String) {
		Assert.isTrue(getExpr().match(EPackage(name)));
	}

	@Test
	public function testImport() {
		var packages:Array<String> = ["test.TestClass", "physics.Box"];
		script = '
		import ${packages[0]};
		import ${packages[1]};
		';
		var expected = EBlock([EImport(packages[0]), EImport(packages[1])]);

		Assert.isTrue(getExpr().match(expected));
	}
}