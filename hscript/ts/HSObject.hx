package hscript.ts;

class HSObject {
    /* Constructor Function */
    public function new():Void {
        pm = new Map();
    }

/* === Instance Methods === */

    /**
      * get a property object
      */
    public inline function getProperty(name:String, create:Bool=true):Null<HSObjectProperty> {
        if (create && !pm.exists( name ))
            pm[name] = new HSObjectProperty( name );
        return pm[name];
    }

    /**
      * define a property
      */
    public function defineProperty(name:String, value:{get:Void->Dynamic, set:Dynamic->Dynamic}):HSObjectProperty {
        var prop = getProperty( name );
        prop.getter = value.get;
        prop.setter = value.set;
        return prop;
    }

    /**
      * check for existence of a property
      */
    public function exists(name : String):Bool {
        return pm.exists( name );
    }

    /**
      * get the value of a given property
      */
    public function get(name : String):Dynamic {
        var prop = getProperty(name, false);
        if (prop == null)
            return null;
        else return prop.get();
    }

    /**
      * set the value of a given property
      */
    public function set(name:String, value:Dynamic):Dynamic {
        return getProperty( name ).set( value );
    }

    /**
      * remove a property
      */
    public function remove(name : String):Bool {
        return pm.remove( name );
    }

    /**
      * iterate over [this] object
      */
    public function iterator():Iterator<HSObjectProperty> {
        return pm.iterator();
    }

    /**
      * iterate over all keys
      */
    public function keys():Iterator<String> {
        return pm.keys();
    }

/* === Instance Fields === */

    private var pm : Map<String, HSObjectProperty>;
}

@:structInit
class HSObjectProperty {
    public var name : String;
    @:optional public var value : Dynamic;
    @:optional public var getter : Void -> Dynamic;
    @:optional public var setter : Dynamic -> Dynamic;

    public function new(name:String, ?value:Dynamic, ?getter:Void->Dynamic, ?setter:Dynamic->Dynamic):Void {
        this.name = name;
        this.value = value;
        this.getter = getter;
        this.setter = setter;
    }

    public inline function get():Dynamic {
        return (getter!=null?getter():value);
    }

    public inline function set(v : Dynamic):Dynamic {
        return ((setter != null) ? setter( v ) : value = v);
    }
}
