package hscript.plus.core;

import massive.munit.Assert;
import hscript.Expr;

@:access(hscript.plus.InterpPlus)
class ClassImporterTest extends TestScriptState {
    var importer:ClassImporter;

    @Before
    override public function setup() {
        super.setup();
        importer = interp.classImporter;
    }

    @Test
    public function testImportFromExpr() {
        importer.importFromExpr(EImport("Sprite"));
        
        Assert.areEqual(Sprite, interp.variables.get("Sprite"));
    }
}