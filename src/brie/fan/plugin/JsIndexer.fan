// History:
//  Feb 02 13 tcolar Creation
//

//using [java] javax.script
//using [java] fanx.interop
//using [java] org.mozilla.javascript

**
** JsIndexer
**
class JsIndexer
{

  static Void main()
  {
/*    js := "sayHello('toto');\nfunction sayHello(name) {\n"
          + "    println('Hello, '+name+'!');\n" + "}"

    ScriptEngineManager factory := ScriptEngineManager()
    ScriptEngine engine := factory
      .getEngineByName("JavaScript")
    ScriptContext context := engine.getContext()
    context.setAttribute("name", "JavaScript",
      ScriptContext.ENGINE_SCOPE)

    Compilable compilingEngine := (Compilable) engine;
    script := compilingEngine.compile(
      "a = 23; fib(num);" +
      "function fib(n) {" +
      "  if(n <= 1) return n; " +
      "  return fib(n-1) + fib(n-2); " +
      "};"
    )
    echo("scopes "+script.getEngine.getContext.getScopes)
    them := script.getEngine.getBindings(ScriptContext.ENGINE_SCOPE).values.toArray
    them[0..-1].each |type|
    {
      try
        dumpType(type)
      catch(Err e){echo(e)}
    }*/
  }

  static Void dumpType(Obj type)
  {
      echo("\n\n*******\n$type")
      try
        echo("ids: "+type->getAllIds)
      catch(Err e) {}
      type.typeof.slots.each
      {
        if(it.isPublic && it.isMethod && ! it.isStatic)
        {
          //echo(it.signature)
          try
          {
            obj := (it as Method).callOn(type, null)
            //if(obj.typeof.signature[0]=='[')
            //{
              echo(it.name +" -> " + obj.typeof.signature + " -> "+obj)
              //dumpType(obj)
            //}
          }
          catch(Err e){echo(it.name)}
        }
      }
    }
  }
