/*
 * Copyright (C)2008-2017 Haxe Foundation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */
package hscript;

import haxe.PosInfos;
import hscript.Expr;

private enum Stop {
	SBreak;
	SContinue;
	SReturn;
}

class Interp {
    /* Constructor Function */
    public function new():Void {
		variables = new Scope();
		locals = new Map();

		declared = new Array();
		variables.set("null", null);
		variables.set("true", true);
		variables.set("false", false);
		variables.set("trace", Reflect.makeVarArgs(function(args: Array<Dynamic>) {
		    //haxe.Log.trace(Std.string(e), posInfos()));
		    if (args.length == 0) {
		        return ;
            }
            else if (args.length == 1) {
                trace(args[0]);
            }
            else {
                var inf = posInfos();
                var v = args.shift();
                if (args.length > 0) {
                    inf.customParams = args;
                }
                haxe.Log.trace(v, inf);
            }
        }));
		initOps();
	}

/* === Instance Methods === */

    /**
      * get the current position info
      */
	public function posInfos(): PosInfos {
		#if hscriptPos
			if (curExpr != null)
				return cast { fileName : curExpr.origin, lineNumber : curExpr.line };
		#end
		return cast { fileName : "hscript", lineNumber : 0 };
	}

    /**
      * initialize operators
      */
	function initOps():Void {
		var me = this;
		#if haxe3
		binops = new Map();
		#else
		binops = new Hash();
		#end
		binops.set("+",function(e1,e2) return me.expr(e1) + me.expr(e2));
		binops.set("-",function(e1,e2) return me.expr(e1) - me.expr(e2));
		binops.set("*",function(e1,e2) return me.expr(e1) * me.expr(e2));
		binops.set("/",function(e1,e2) return me.expr(e1) / me.expr(e2));
		binops.set("%",function(e1,e2) return me.expr(e1) % me.expr(e2));
		binops.set("&",function(e1,e2) return me.expr(e1) & me.expr(e2));
		binops.set("|",function(e1,e2) return me.expr(e1) | me.expr(e2));
		binops.set("^",function(e1,e2) return me.expr(e1) ^ me.expr(e2));
		binops.set("<<",function(e1,e2) return me.expr(e1) << me.expr(e2));
		binops.set(">>",function(e1,e2) return me.expr(e1) >> me.expr(e2));
		binops.set(">>>",function(e1,e2) return me.expr(e1) >>> me.expr(e2));
		binops.set("==",function(e1,e2) return me.expr(e1) == me.expr(e2));
		binops.set("!=",function(e1,e2) return me.expr(e1) != me.expr(e2));
		binops.set(">=",function(e1,e2) return me.expr(e1) >= me.expr(e2));
		binops.set("<=",function(e1,e2) return me.expr(e1) <= me.expr(e2));
		binops.set(">",function(e1,e2) return me.expr(e1) > me.expr(e2));
		binops.set("<",function(e1,e2) return me.expr(e1) < me.expr(e2));
		binops.set("||",function(e1,e2) return me.expr(e1) == true || me.expr(e2) == true);
		binops.set("&&",function(e1,e2) return me.expr(e1) == true && me.expr(e2) == true);
		binops.set("=",assign);
		binops.set("...",function(e1,e2) return new #if (haxe_211 || haxe3) IntIterator #else IntIter #end(me.expr(e1),me.expr(e2)));
		assignOp("+=",function(v1:Dynamic,v2:Dynamic) return v1 + v2);
		assignOp("-=",function(v1:Float,v2:Float) return v1 - v2);
		assignOp("*=",function(v1:Float,v2:Float) return v1 * v2);
		assignOp("/=",function(v1:Float,v2:Float) return v1 / v2);
		assignOp("%=",function(v1:Float,v2:Float) return v1 % v2);
		assignOp("&=",function(v1,v2) return v1 & v2);
		assignOp("|=",function(v1,v2) return v1 | v2);
		assignOp("^=",function(v1,v2) return v1 ^ v2);
		assignOp("<<=",function(v1,v2) return v1 << v2);
		assignOp(">>=",function(v1,v2) return v1 >> v2);
		assignOp(">>>=",function(v1,v2) return v1 >>> v2);
	}

    /**
      * assignment
      */
	function assign(e1:Expr, e2:Expr):Dynamic {
		var v = expr(e2);
		switch (edef( e1 )) {
		    // variable assignment
            case EIdent(id):
                var l = locals.get(id);
                if( l == null )
                    variables.set(id,v)
                else
                    l.r = v;

            // dot-field assignment
            case EField(e,f):
                v = set(expr(e), f, v);

            // array-access assignment
            case EArray(e, index):
                var arr:Dynamic = expr(e);
                var index:Dynamic = expr(index);
                if (isMap(arr)) {
                    setMapValue(arr, index, v);
                }
                else {
                    arr[index] = v;
                }

            default:
                error(EInvalidOp("="));
		}
		return v;
	}

    /**
      * declare an assignment operator
      */
	function assignOp( op, fop : Dynamic -> Dynamic -> Dynamic ) {
		var me = this;
		binops.set(op,function(e1,e2) return me.evalAssignOp(op,fop,e1,e2));
	}

    /**
      * evaluate assignment operator
      */
	private function evalAssignOp(op,fop,e1,e2) : Dynamic {
		var v;
		switch( edef(e1) ) {
		case EIdent(id):
			var l = locals.get(id);
			v = fop(expr(e1),expr(e2));
			if( l == null )
				variables.set(id,v)
			else
				l.r = v;
		case EField(e,f):
			var obj = expr(e);
			v = fop(get(obj,f),expr(e2));
			v = set(obj,f,v);
		case EArray(e, index):
			var arr:Dynamic = expr(e);
			var index:Dynamic = expr(index);
			if (isMap(arr)) {
				v = fop(getMapValue(arr, index), expr(e2));
				setMapValue(arr, index, v);
			}
			else {
				v = fop(arr[index],expr(e2));
				arr[index] = v;
			}
		default:
			return error(EInvalidOp(op));
		}
		return v;
	}

    /**
      * perform incrementation
      */
	private function increment(e:Expr, prefix:Bool, delta:Int):Dynamic {
		#if hscriptPos
		curExpr = e;
		var e = e.e;
		#end
        switch ( e ) {
            case EIdent(id):
                var l = locals.get(id);
                var v : Dynamic = (l == null) ? variables.get(id) : l.r;
                if( prefix ) {
                    v += delta;
                    if( l == null ) variables.set(id,v) else l.r = v;
                } else
                    if( l == null ) variables.set(id,v + delta) else l.r = v + delta;
                return v;

            case EField(e,f):
                var obj = expr(e);
                var v : Dynamic = get(obj,f);
                if( prefix ) {
                    v += delta;
                    set(obj,f,v);
                } else
                    set(obj,f,v + delta);
                return v;

            case EArray(e, index):
                var arr:Dynamic = expr(e);
                var index:Dynamic = expr(index);
                if (isMap(arr)) {
                    var v = getMapValue(arr, index);
                    if (prefix) {
                        v += delta;
                        setMapValue(arr, index, v);
                    }
                    else {
                        setMapValue(arr, index, v + delta);
                    }
                    return v;
                }
                else {
                    var v = arr[index];
                    if( prefix ) {
                        v += delta;
                        arr[index] = v;
                    } else
                        arr[index] = v + delta;
                    return v;
                }

            default:
                return error(EInvalidOp((delta > 0)?"++":"--"));
		}
	}

    /**
      * execute the given expression
      */
	public function execute(expr : Expr):Dynamic {
		depth = 0;
		#if haxe3
		locals = new Map();
		#else
		locals = new Hash();
		#end
		declared = new Array();
		return exprReturn(expr);
	}

    /**
      * evaluate [e] for its return value
      */
	function exprReturn(e : Expr):Dynamic {
		try {
			return expr(e);
		} 
		catch( e : Stop ) {
			switch( e ) {
			case SBreak: throw "Invalid break";
			case SContinue: throw "Invalid continue";
			case SReturn:
				var v = returnValue;
				returnValue = null;
				return v;
			}
		}
		return null;
	}

    /**
      * duplicate the given Map/Hash
      */
	private function duplicate<T>( h : #if haxe3 Map < String, T > #else Hash<T> #end ) {
		#if haxe3
		var h2 = new Map();
		#else
		var h2 = new Hash();
		#end
		for( k in h.keys() )
			h2.set(k,h.get(k));
		return h2;
	}

    /**
      * restore to some previous scope level
      */
	private function restore(old : Int):Void {
		while( declared.length > old ) {
			var d = declared.pop();
			locals.set(d.n,d.old);
		}
	}

    /**
      * get the ExprDef enum value from [e]
      */
	private inline function edef(e : Expr) {
		#if hscriptPos
		return e.e;
		#else
		return e;
		#end
	}

    /**
      * throw an error
      */
	private inline function error(e : #if hscriptPos ErrorDef #else Error #end ):Dynamic {
		#if hscriptPos
		throw new Error(e, curExpr.pmin, curExpr.pmax, curExpr.origin, curExpr.line);
		#else
		throw e;
		#end
		return null;
	}

    /**
      * resolve the value of a variable by name
      */
	public function resolve(id:String, safe:Bool=true):Dynamic {
		var l = locals.get(id);
		if( l != null )
			return l.r;
		var v = variables.get(id);
		if(v == null && !variables.exists(id) && safe)
			error(EUnknownVariable(id));
		return v;
	}

    /**
     * interpret the expression [e] and return its return-value
     */
    public function expr( e : Expr ) : Dynamic {
        #if hscriptPos
        curExpr = e;
        var e = e.e;
        #end

        switch( e ) {
            // constants
            case EConst(c):
                switch( c ) {
                    case CInt(v): return v;
                    case CFloat(f): return f;
                    case CString(s): return s;
                    #if !haxe3
                    case CInt32(v): return v;
                    #end
                }

                // identifiers
            case EIdent( id ):
                return resolve( id );

                // variable declaration
            case EVar(n, _, e):
                declared.push({
                    n: n,
                    old: locals.get(n) 
                });
                locals.set(n, {
                    r: ((e == null) ? null : expr(e))
                });
                return null;

                // parenthesized expression
            case EParent( e ):
                return expr( e );

                // block expression
            case EBlock( exprs ):
                var old = declared.length;
                var v = null;
                for (e in exprs)
                    v = expr(e);
                restore(old);
                return v;

                // dot-field access
            case EField(e, f):
                return get(expr(e),f);

                // binary operators
            case EBinop(op, e1, e2):
                var fop = binops.get(op);
                if (fop == null) 
                    error(EInvalidOp(op));
                return fop(e1,e2);

                // unary operators
            case EUnop(op,prefix,e):
                switch(op) {
                    case "!":
                        return expr(e) != true;
                    case "-":
                        return -expr(e);
                    case "++":
                        return increment(e,prefix,1);
                    case "--":
                        return increment(e,prefix,-1);
                    case "~":
                        #if(neko && !haxe3)
                        return haxe.Int32.complement(expr(e));
                        #else
                        return ~expr(e);
                        #end

                    default:
                        error(EInvalidOp( op ));
                        return null;
                }

                // function invokation
            case ECall(e,params):
                var args = new Array();
                for( p in params )
                    args.push(expr(p));

                switch(edef( e )) {
                    case EField(e, f):
                        var obj = expr(e);
                        if( obj == null ) error(EInvalidAccess(f));
                        return fcall(obj,f,args);
                    default:
                        return call(null,expr(e),args);
                }

                // if statement
            case EIf(econd, e1, e2):
                return if(expr(econd) == true) expr(e1) else if (e2 == null) null else expr(e2);

                // while loop
            case EWhile(econd, e):
                whileLoop(econd, e);
                return null;

                // do while loop
            case EDoWhile(econd, e):
                doWhileLoop(econd, e);
                return null;

                // for loop
            case EFor(v,it,e):
                forLoop(v,it,e);
                return null;

                // break statement
            case EBreak:
                throw SBreak;

                // continue statement
            case EContinue:
                throw SContinue;

                // return statement
            case EReturn(e):
                throw SReturn((e == null)?null:expr(e));

                // function definition
            case EFunction(params, fexpr, name, _):
                var capturedLocals = duplicate(locals);
                var me = this;
                var hasOpt = false, minParams = 0;
                for( p in params )
                    if( p.opt )
                        hasOpt = true;
                    else
                        minParams++;
                var f = function(args:Array<Dynamic>) {
                    if( args.length != params.length ) {
                        if( args.length < minParams ) {
                            var str = "Invalid number of parameters. Got " + args.length + ", required " + minParams;
                            if( name != null ) str += " for function '" + name+"'";
                            throw str;
                        }
                        // make sure mandatory args are forced
                        var args2 = [];
                        var extraParams = args.length - minParams;
                        var pos = 0;
                        for( p in params )
                            if( p.opt ) {
                                if( extraParams > 0 ) {
                                    args2.push(args[pos++]);
                                    extraParams--;
                                } else
                                    args2.push(null);
                            } else
                                args2.push(args[pos++]);
                        args = args2;
                    }
                    var old = me.locals, depth = me.depth;
                    me.depth++;
                    me.locals = me.duplicate(capturedLocals);
                    for( i in 0...params.length )
                        me.locals.set(params[i].name,{ r : args[i] });
                    var r = null;
                    if ( inTry ) {
                        try {
                            r = me.exprReturn(fexpr);
                        } 
                        catch(e : Dynamic) {
                            me.locals = old;
                            me.depth = depth;
#if neko
                            neko.Lib.rethrow(e);
#else
                            throw e;
#end
                        }
                    }
                    else {
                        r = me.exprReturn(fexpr);
                    }
                    me.locals = old;
                    me.depth = depth;
                    return r;
                };
                var f = Reflect.makeVarArgs( f );
                if (name != null) {
                    if (depth == 0) {
                        // global function
                        variables.set(name, f);
                    } 
                    else {
                        // function-in-function is a local function
                        declared.push({
                            n: name,
                            old: locals.get(name) 
                        });
                        var ref = {r: f};
                        locals.set(name, ref);
                        capturedLocals.set(name, ref); // allow self-recursion
                    }
                }
                return f;

                // array/map declaration
            case EArrayDecl(arr):
                if (arr.length > 0 && edef(arr[0]).match(EBinop("=>", _))) {
                    var isAllString:Bool = true;
                    var isAllInt:Bool = true;
                    var isAllObject:Bool = true;
                    var isAllEnum:Bool = true;
                    var keys:Array<Dynamic> = [];
                    var values:Array<Dynamic> = [];
                    for (e in arr) {
                        switch(edef( e )) {
                            case EBinop("=>", eKey, eValue): {
                                var key:Dynamic = expr(eKey);
                                var value:Dynamic = expr(eValue);
                                isAllString = isAllString && Std.is(key, String);
                                isAllInt = isAllInt && Std.is(key, Int);
                                isAllObject = isAllObject && Reflect.isObject(key);
                                isAllEnum = isAllEnum && Reflect.isEnumValue(key);
                                keys.push(key);
                                values.push(value);
                            }
                            default: throw("=> expected");
                        }
                    }
                    var map:Dynamic = {
                        if (isAllInt) new haxe.ds.IntMap<Dynamic>();
                        else if (isAllString) new haxe.ds.StringMap<Dynamic>();
                        else if (isAllEnum) new haxe.ds.EnumValueMap<Dynamic, Dynamic>();
                        else if (isAllObject) new haxe.ds.ObjectMap<Dynamic, Dynamic>();
                        else throw 'Inconsistent key types';
                    }
                    for (n in 0...keys.length) {
                        setMapValue(map, keys[n], values[n]);
                    }
                    return map;
                }
                else {
                    var a = new Array();
                    for (e in arr) {
                        a.push(expr( e ));
                    }
                    return a;
                }

                // array access
            case EArray(e, index):
                var arr:Dynamic = expr(e);
                var index:Dynamic = expr(index);
                if (isMap(arr)) {
                    return getMapValue(arr, index);
                }
                else {
                    return arr[index];
                }

                // new object creation
            case ENew(cl, params):
                var a = new Array();
                for( e in params )
                    a.push(expr(e));
                return cnew(cl,a);

                // throw statement
            case EThrow( e ):
                throw expr( e );

                // try...catch statement
            case ETry(e, n, _, ecatch):
                var old = declared.length;
                var oldTry = inTry;
                try {
                    inTry = true;
                    var v:Dynamic = expr( e );
                    restore( old );
                    inTry = oldTry;
                    return v;
                }
                catch(err : Stop) {
                    inTry = oldTry;
                    throw err;
                }
                catch(err : Dynamic) {
                    // restore vars
                    restore( old );
                    inTry = oldTry;
                    // declare 'v'
                    declared.push({ 
                        n: n,
                        old: locals.get(n) 
                    });
                    locals.set(n, {r: err});
                    var v:Dynamic = expr( ecatch );
                    restore( old );
                    return v;
                }

                // object declaration
            case EObject( fl ):
                var o = {};
                for( f in fl )
                    set(o, f.name, expr( f.e ));
                return o;

                // ternary statement
            case ETernary(econd, e1, e2):
                return {
                    if (expr( econd ) == true) 
                        expr( e1 );
                    else
                        expr( e2 );
                };

                // switch statement
            case ESwitch(e, cases, def):
                var val : Dynamic = expr(e);
                var match = false;
                for( c in cases ) {
                    for( v in c.values )
                        if( expr(v) == val ) {
                            match = true;
                            break;
                        }
                    if( match ) {
                        val = expr(c.expr);
                        break;
                    }
                }
                if( !match )
                    val = def == null ? null : expr(def);
                return val;

            // metadata statement
            case EMeta(_, _, e):
                return expr(e);

            // any other expression
            default:
                return null;
        }
    }

    /**
      * perform a do...while loop
      */
	private function doWhileLoop(econd:Expr, e:Expr) {
		var old = declared.length;
		do {
			try {
				expr( e );
			} 
			catch (err : Stop) {
				switch(err) {
				case SContinue:
				case SBreak: break;
				case SReturn: throw err;
				}
			}
		}
		while (expr(econd) == true);
		restore( old );
	}

    /**
      * perform a while loop
      */
	private function whileLoop(econd,e) {
		var old = declared.length;
		while( expr(econd) == true ) {
			try {
				expr(e);
			} catch( err : Stop ) {
				switch(err) {
				case SContinue:
				case SBreak: break;
				case SReturn: throw err;
				}
			}
		}
		restore(old);
	}

    /**
      * attempt to get an iterator from [v]
      */
	private function makeIterator(v : Dynamic):Iterator<Dynamic> {
		#if ((flash && !flash9) || (php && !php7 && haxe_ver < '4.0.0'))
		if ( v.iterator != null ) v = v.iterator();
		#else
		try v = v.iterator() catch( e : Dynamic ) {};
		#end
		if( v.hasNext == null || v.next == null ) error(EInvalidIterator(v));
		return v;
	}

    /**
      * perform for loop
      */
	private function forLoop(n, it, e) {
		var old = declared.length;
		declared.push({ n : n, old : locals.get(n) });
		var it = makeIterator(expr( it ));
		while (it.hasNext()) {
			locals.set(n, {
			    r: it.next()
			});
			try {
				expr(e);
			} 
			catch (err : Stop) {
				switch( err ) {
				case SContinue:
				case SBreak: break;
				case SReturn: throw err;
				}
			}
		}
		restore( old );
	}

    /**
      * check whether [o] is a Map
      */
	private inline function isMap(o:Dynamic):Bool {
		return Std.is(o, haxe.Constraints.IMap);
	}
	
	/**
	  * get value from Map
	  */
	private inline function getMapValue(map:Dynamic, key:Dynamic):Dynamic {
		return cast(map, haxe.Constraints.IMap<Dynamic, Dynamic>).get(key);
	}

    /**
      * set value on Map
      */
	private inline function setMapValue(map:Dynamic, key:Dynamic, value:Dynamic):Void {
		cast(map, haxe.Constraints.IMap<Dynamic, Dynamic>).set(key, value);
	}
	
	/**
	  * dot-property access
	  */
	function get(o:Dynamic, f:String):Dynamic {
		if ( o == null ) error(EInvalidAccess(f));
		return {
			#if php
				// https://github.com/HaxeFoundation/haxe/issues/4915
				try {
					Reflect.getProperty(o, f);
				} catch (e:Dynamic) {
					Reflect.field(o, f);
				}
			#else
				Reflect.getProperty(o, f);
			#end
		}
	}

    /**
      * dot-property assignment
      */
	private function set(o:Dynamic, f:String, v:Dynamic):Dynamic {
		if (o == null) 
		    error(EInvalidAccess( f ));
		Reflect.setProperty(o, f, v);
		return v;
	}

    /**
      * invoke method [f] of object [o]
      */
	private function fcall(o:Dynamic, f:String, args:Array<Dynamic>):Dynamic {
		return call(o, get(o, f), args);
	}

    /**
      * invoke function [f] with arguments [args]
      */
	private function call(o:Dynamic, f:Dynamic, args:Array<Dynamic>):Dynamic {
		return Reflect.callMethod(o, f, args);
	}

    /**
      * create a new class instance
      */
	private function cnew(cl:String, args:Array<Dynamic>):Dynamic {
		var c = Type.resolveClass(cl);
		if( c == null ) c = resolve(cl);
		return Type.createInstance(c,args);
	}

/* === Instance Fields === */

	//public var variables : Map<String,Dynamic>;
	public var variables : Scope;
	private var locals : Map<String,{ r : Dynamic }>;
	var binops : Map<String, Expr -> Expr -> Dynamic >;

	var depth : Int;
	var inTry : Bool;
	var declared : Array<{ n : String, old : { r : Dynamic } }>;

	#if hscriptPos
	var curExpr : Expr;
	#end
}

private enum Stop {
	SBreak;
	SContinue;
	SReturn( v : Dynamic );
}
