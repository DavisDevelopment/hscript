package hscript.plus;

import hscript.Expr;
import hscript.plus.core.*;

class InterpPlus extends Interp {
	//public var globals(default, null):Map<String, Dynamic>;
    public var globals(default, null): Scope;

	private var classImporter:ClassImporter;
	private var eclassInterp:InterpEClass;

	private var exprSteps:Array<Expr->Dynamic> = [];

	override function assign(e1:Expr, e2:Expr):Dynamic {
		var assignedValue = expr( e2 );
		switch (edef( e1 )) {
			case EIdent( id ):
				var object = globals.get( "this" );
				if (object != null)
					Reflect.setField(object, id, assignedValue);
			default:
		}

		super.assign(e1, e2);
		return assignedValue;
	}

	public function new() {
		super();

		globals = variables;

		classImporter = new ClassImporter( this );

		setupExprSteps();
	}

	public function setResolveImportFunction(func: String->Dynamic) {
		classImporter.setResolveImportFunction(func);
	}

	private function setupExprSteps() {
		pushExprStep(InterpECall.expr.bind(this));
		pushExprStep(superExpr);
		pushExprStepVoid(classImporter.importFromExpr);
		pushExprStep(InterpEClass.expr.bind(this));
	}

	private function pushExprStepVoid(stepVoid:Expr->Void) {
		var  step = e -> { stepVoid(e); return null; };
		pushExprStep(step);
	}

	private function pushExprStep(step: Expr->Dynamic) {
		exprSteps.push( step );
	}

	public function superExpr(e:Expr):Dynamic {
		return super.expr(e);
	}

	override public function expr(e: Expr):Dynamic {
		return startExprSteps( e );
	}

	private function startExprSteps(e: Expr):Dynamic {
		var ret:Dynamic = null;
		for (step in exprSteps) {
			ret = step( e );
			if (ret != null)
				break;
		}
		return ret;
	}

	override function get(o:Dynamic, f:String):Dynamic {
		//this.classImporter
		return InterpGet.get(this, o, f);
	}

	override function call(o:Dynamic, f:Dynamic, args:Array<Dynamic>):Dynamic {
	    if (Reflect.hasField(o, 'super') && f == o.super) {
	        return super.call(o, Reflect.getProperty(f, 'new'), args);
	    }
        else return super.call(o, f, args);
	}

	override function resolve(id:String, safe:Bool=true):Dynamic {
		return InterpResolve.resolve(this, id);
	}

	override function cnew(className:String, args:Array<Dynamic>):Dynamic {
		return InterpCnew.cnew(this, className, args);
	}

	public function superCnew(className:String, args:Array<Dynamic>) {
		return super.cnew(className, args);
	}

	public function superResolve(className:String) {
		return super.resolve(className);
	}

	public function superGet(o:Dynamic, f:String):Dynamic {
		return super.get(o, f);
	}
}
