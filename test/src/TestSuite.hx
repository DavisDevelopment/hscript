import massive.munit.TestSuite;

import hscript.plus.core.ClassImporterTest;
import hscript.plus.core.DynamicCreatorTest;
import hscript.plus.core.DynamicFunTest;
import hscript.plus.core.InterpECallTest;
import hscript.plus.core.InterpEClassTest;
import hscript.plus.core.InterpGetTest;
import hscript.plus.core.InterpResolveTest;
import hscript.plus.InterpPlusTest;
import hscript.plus.ParserPlusTest;
import hscript.plus.ScriptStateTest;

/**
 * Auto generated Test Suite for MassiveUnit.
 * Refer to munit command line tool for more information (haxelib run munit)
 */

class TestSuite extends massive.munit.TestSuite
{		

	public function new()
	{
		super();

		add(hscript.plus.core.ClassImporterTest);
		add(hscript.plus.core.DynamicCreatorTest);
		add(hscript.plus.core.DynamicFunTest);
		add(hscript.plus.core.InterpECallTest);
		add(hscript.plus.core.InterpEClassTest);
		add(hscript.plus.core.InterpGetTest);
		add(hscript.plus.core.InterpResolveTest);
		add(hscript.plus.InterpPlusTest);
		add(hscript.plus.ParserPlusTest);
		add(hscript.plus.ScriptStateTest);
	}
}
