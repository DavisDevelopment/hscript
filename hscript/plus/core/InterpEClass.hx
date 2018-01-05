package hscript.plus.core;

import hscript.Expr;

class InterpEClass {
	static var interp: InterpPlus;
	static var globals: Scope;

	static var name: String;
	static var eclass: Expr;
	static var superClassName: String;
	static var classObject: Dynamic;
	static var classDecl: ClassDecl;

    public static function expr(interp:InterpPlus, expr:Expr):Dynamic {
		InterpEClass.interp = interp;
		globals = interp.variables;

        return createClassIfIsEClass( expr );
    }

    /**
      * if an EClass expr is provided, creates and returns a Class
      */
	static function createClassIfIsEClass(expr: Expr) {
		switch (ExprHelper.getExprDef( expr )) {
			case EClass(name, e, superClassName):
				referenceProperties(name, e, superClassName);
				return createClass();

			default:
				return null;
		}
	}

	static function referenceProperties(n:String, e:Expr, s:String) {
		name = n;
		eclass = e;
		superClassName = s;
	}

	static function createClass() {
		createClassObject();
		addFieldsToClassObjectFromParsingBlock();
		addClassObjectToGlobals();
		return classObject;
	}

	static function createClassObject() {
		var superClass = getSuperClassFromGlobals();
		classObject = DynamicFun.create(interp, name, superClass);

		classDecl = {
            name: name,
            params: {},
            extend: null,
            implement: [],
            fields: [],
            meta: new Metadata()
		};
	}

	static function getSuperClassFromGlobals() {
		return superClassName == null ? null : globals.get(superClassName);
	}

    /**
      * parse out and add fields to the class
      */
	static function addFieldsToClassObjectFromParsingBlock() {
		switch (ExprHelper.getExprDef( eclass )) {
			case EBlock( exprList ):
				for (e in exprList) {
					addVarsAndFunctions(classObject, e);
					addFieldDecls(classDecl, e);
                }

			default:
		}
	}

    /**
      * expose the class into the global scope
      */
	static function addClassObjectToGlobals() {
	    untyped classObject.__decl__ = classDecl;
		globals.set(name, classObject);
	}

	/**
	  * attach properties and methods to [classDecl]
	  */
	static function addFieldDecls(classType:ClassDecl, e:Expr) {
	    switch (ExprHelper.getExprDef( e )) {
            case EFunction(args, body, name, ret, access):
                add(method(name, args, body, ret, null, access));

            case EVar(name, type, expr, access):
                add(property(name, type, expr, null, null, null, access));

            default:
	    }
	}

	static inline function add(decl: FieldDecl) {
	    if (classDecl != null)
	        classDecl.fields.push( decl );
	}

	static inline function funcDecl(args:Array<Argument>, body:Expr, ?returnType:CType):FunctionDecl {
	    return {args:args, expr:body, ret: returnType};
	}

	static inline function varDecl(?type:CType, ?expr:Expr, ?get:String, ?set:String):VarDecl {
	    return {get:get, set:set, type:type, expr:expr};
	}

	static inline function property(name:String, ?type:CType, ?expr:Expr, ?get:String, ?set:String, ?meta:Metadata, ?access:Array<FieldAccess>) {
	    return field(name, KVar(varDecl(type, expr, get, set)), meta, access);
	}

	static inline function method(name:String, args:Array<Argument>, body:Expr, ?returnType:CType, ?meta:Metadata, ?access:Array<FieldAccess>) {
	    return field(name, KFunction(funcDecl(args, body, returnType)), meta, access);
	}

    /**
      * helper method for creating and returning FieldDecl objects
      */
	static inline function field(name:String, kind:FieldKind, ?meta:Metadata, ?access:Array<FieldAccess>):FieldDecl {
	    return {
            name: name,
            kind: kind,
            access: (access != null ? access : [APrivate]),
            meta: (meta != null ? meta : new Metadata())
	    };
	}

    /**
      * attach properties and methods to [classType]
      */
	static function addVarsAndFunctions(classType:Dynamic, e:Expr) {
		switch (ExprHelper.getExprDef(e)) {
			case EFunction(args, _, name, _, access):
				setClassField(classType, name, e, access);
			case EVar(name, _, e, access):
				setClassField(classType, name, e, access);
			default:
		}
	}

    /**
      * attach a class field to [object]
      */
	static function setClassField(object:Dynamic, name:String, e:Expr, access:Array<FieldAccess>) {
		var field = interp.superExpr(e);
		Reflect.setField(object, name, field);
	}
}
