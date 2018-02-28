package hscript.plus;

import haxe.CallStack;
import hscript.Expr;

using StringTools;

@:access( hscript.Interp )
@:access( hscript.Parser )
class ScriptState {
    /* Constructor Function */
    public function new() {
        parser = new ParserPlus();
        parser.allowTypes = true;
        parser.allowMetadata = true;
        parser.allowJSON = true;

        rethrowError = true;

        interp = new InterpPlus();
        interp.setResolveImportFunction( resolveImport );
    }

    /**
      * resolve an 'import' statement
      */
    function resolveImport(packageName: String):Dynamic {
        var scriptPath = _scriptPathMap.get( packageName );
        executeFile( scriptPath );
        var className = packageName.split(".").pop();
        return get( className );
    }

    /**
      * get the value of a variable
      */
    public inline function get(name:String):Dynamic {
        return interp.variables.get( name );
    }

    /**
      * assign the value of a variable
      */
    public inline function set(name:String, val:Dynamic) {
        return interp.variables.set(name, val);
    }

    /**
      * read, parse, and execute the given Path
      */
    public function executeFile(path: String) {
        if (getFileContent == null) {
            error("Provide a getFileContent function first!");
            if ( !rethrowError )
                return null;
        }
        this.path = path;
        var script = getFileContent( path );
        return executeString( script );
    }

    /**
      * parse and execute the given String
      */
    public function executeString(script: String):Dynamic {
        path = 'test_script.js';
        ast = parseScript( script );
        return execute( ast );
    }

    /**
      * parse the given String
      */
    public function parseScript(script: String):Null<Expr> {
        try {
            return parser.parseString(script, path);
        }
        catch (e: Dynamic) {
            #if hscriptPos 
            error('$path:${e.line}: characters ${e.pmin} - ${e.pmax}: $e'); 
            #else 
            error( e ); 
            #end 
            return null;
        }
    }

    /**
      * execute the given AST, and return its output
      */
    public function execute(ast:Expr):Dynamic {
        try {
            var val = interp.execute( ast );
            var main = get( "main" );

            if (main != null && Reflect.isFunction( main ))
                return main();
            else return val;
        }
        catch (e: Dynamic) {
            error(e + CallStack.toString(CallStack.exceptionStack()));
            trace('Debug AST: $ast');
        }
        return null;
    }

    private function error(e:Dynamic) {
        if (rethrowError)
            throw e;
        else trace(e);
    }

    private function set_scriptDirectory(newDirectory:String) {
        if (!newDirectory.endsWith("/"))
            newDirectory += "/";
        loadScriptFromDirectory(scriptDirectory = newDirectory);
        return newDirectory;
    }

    /**
     *  Create a map of package name as keys to paths
     *  @param directory The directory containing the script files
     */
    function loadScriptFromDirectory(directory:String) {
        var paths:Array<String> = null;

        if (getScriptPaths != null)
            paths = getScriptPaths();
        else if (getScriptPathsFromDirectory != null)
            paths = getScriptPathsFromDirectory(directory);
        else error('Provide a function for getScriptPaths or getScriptPathsFromDirectory');

        // filter out paths not ending with ".hx"
        paths = paths.filter(path -> path.endsWith(".hx"));
        // prepend the directory to the path if it doesn't start with the directory
        paths = paths.map(path -> {
            return
                if (path.startsWith(directory))
                    path
                else directory + path;
        });

        _scriptPathMap = [for (path in paths) {
            getPackageName( path ) => path;
        }];
    }

    function getPackageName(path:String) {
        path = path.replace(scriptDirectory, "");
        path = path.replace(".hx", "");
        return path.replace("/", ".");
    }

/* === Instance Fields === */

    /**
      * global-level variable scope
      */
    public var variables(get, null):Scope;
    private inline function get_variables() return interp.variables;

    /**
      * method used for reading files
      */
    public var getFileContent:String->String;
    //if sys = sys.io.File.getContnt;
    //#elseif openfl = openfl.Assets.getText
    //#nd; 

    public var getScriptPaths:Void->Array<String> #if openfl = () -> openfl.Assets.list() #end;

    public var getScriptPathsFromDirectory:String->Array<String> #if sys = sys.FileSystem.readDirectory #end;

    public var scriptDirectory(default, set):String;

    /**
     *  If set to `true`, rethrow errors
     *  or just trace the errors when set to `false`
     */
    public var rethrowError:Bool = #if debug true #else false #end;

    /**
     *  The last Expr executed
     *  Used for debugging
     */
    public var ast(default, null):Expr;

    /**
     *  The last path whose text was executed
     *  Used for debugging
     */
    public var path(default, null):String;

    /**
     *  Map<PackageName, Path>
     */
    private var _scriptPathMap:Map<String, String> = new Map();

    public var parser(default, null): ParserPlus;
    public var interp(default, null): InterpPlus;
}
