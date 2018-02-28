package;

class Sprite {
    public var name:String;
    public var mass:Int;
    
    public function new() {
        name = "";
        mass = 100;
    }

    public function setMass(newMass:Int) {
        mass = newMass;
    }
}