package;

import massive.munit.Assert;
import hscript.Expr;
import hscript.plus.ParserPlus;
import hscript.plus.InterpPlus;

@:access(hscript.plus.InterpPlus.prependSuper)
class TestScriptState {
	var parser:ParserPlus;
    var interp:InterpPlus;

	var astTraceRequested:Bool = false;
	var scriptReturn:Dynamic;

	var script(default, set):String;
	var pass(get, never):Bool;

	public function new() {}

	@Before
	public function setup() {
		parser = new ParserPlus();
        interp = new InterpPlus();

		set("Assert", Assert);
		set("pass", false);
	}

	inline function set(name:String, value:Dynamic) {
		return interp.variables.set(name, value);
	}

	inline function setMany(variables:Dynamic) {
		for (name in Reflect.fields(variables)) {
            var value = Reflect.field(variables, name);
            set(name, value);
        }
	}

	inline function get(name:String) {
		return interp.variables.get(name);
	}

	inline function requestAstTrace() {
		astTraceRequested = true;
	}

	function set_script(newScript:String) {
		script = newScript;
		var ast = parseToAst();
		traceAstOnceIfRequested(ast);
		execute(ast);
		return newScript;
	}

	function parseToAst() {
		return parser.parseString(script);
	}

	function traceAstOnceIfRequested(ast:Expr) {
		if (astTraceRequested) {
			trace(ast);
			astTraceRequested = false;
		}
	}

	function execute(ast:Expr) {
		return scriptReturn = interp.execute(ast);
	}

	function get_pass() {
		return get("pass");
	}
}