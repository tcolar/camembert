// History:
//  Mar 07 13 tcolar Creation
//

using camembert
using gfx
using web
using concurrent
using util

**
** PythonDocs : Provides help pane documentation for Python
**
const class PythonDocs : PluginDocs
{
  override const Image? icon := Image(`fan://camPythonPlugin/res/python.png`, false)

  const AtomicRef _docs := AtomicRef()

  new make() : super()
  {
    // Force "reindexing" docs at each start (for now)
    clearIndex

    reindex
  }

  ** name of the plugin responsible
  override Str pluginName() {this.typeof.pod.name}

  ** User friendly dsplay name
  override Str dis() {"Python"}

  ** Return a FileItem for the document matching the current source file (if known)
  ** Query wil be what's in the helPane serach box, ie "fwt::Combo#make" (not prefixed by plugin name)
  override FileItem? findSrc(Str query) {null}

  ** Return html for a given path
  ** Note, the query will be prefixed with the plugin name for example /fantom/fwt::Button
  override Str html(WebReq req, Str query, MatchKind matchKind)
  {
    // TODO
    return ""
  }

  ** Return ruby index
  Str index(File ri)
  {
    // TODO
    return ""
  }

  ** Check if str looks like it might be a ruby id(class, method, etc...)
  ** Allowing alphanums and _, ?, !, =
  ** This is unperfect but decent enough for this purpose (doc links)
  private Bool mightBeId(Str s)
  {
    return s.chars.eachWhile |Int c -> Int?|
    {
      if(c.isAlphaNum || c == '_' || c == '?' || c == '!' || c == '=')
        return null
      return c
    } == null
  }*/


  Void clearIndex()
  {
    (Sys.cur.optionsFile + `../state/`).listFiles.each
    {
      if(it.name.startsWith("python_info_"))
        it.delete
    }
  }

  ** Index the docs for the current python env
  ** only reindex if we don't have it generated yet for the current env
  ** use clearIndex first to force reindexing
  Void reindex()
  {
    Actor(ActorPool(), |Obj? obj -> Obj?|
    {
      try
      {
        config := PluginManager.cur.conf(dis) as BasicConfig
        if(config == null) return "Missing config"
        env := config.curEnv as BasicEnv
        if(env == null) return "Missing env"
        python := env.envHome.toFile + `bin/python`
        if( ! python.exists) return "pythonPath is not set properly in the python env !"

        version := runPython(python, ["--version"]).readAllStr[7 .. -1]

        info := Sys.cur.optionsFile + `../state/python_info_${version}.json`

        if(! info.exists)
          runPython(python, ["", info.osPath])
        Obj? theDocs := JsonInStream(info.in).readJson

        _docs.val = scan(theDocs)
      }
      catch(Err e)
      {
        Sys.log.err("Failed loading Node.js docs !", e)
      }
      return null
    }).send("run")
  }

  ** Read json genarted from python and create in memory doc map from it.
  Str:PythonDoc scan(Obj? obj)
  {
    Str:PythonDoc docs := [:]
    if(obj == null || ! (obj is List)) return docs
    (obj as List).each
    {
      map := (it as Str:Str?)
      doc := PythonDoc(map)
      docs[doc.sig] = doc
    }
    return docs.toImmutable
  }

  private Buf runPython(File python, Str[] args)
  {
    p := Process([python.osPath].addAll(args))
    b := Buf()
    p.out = b.out
    p.run.join
    return b.flip
  }
}

** Python documentation nodes
@Serializable
const class PythonDoc
{
  const Str type := ""
  const Str name := ""
  const Str module := ""
  const Str clazz := ""
  const Str file := ""
  const Str line := ""
  const Str doc := ""
  const Str sig := ""

  new make(Str:Obj? map)
  {
    type = map["type"]?.toStr ?: ""
    name = map["name"]?.toStr ?: ""
    module = map["module"]?.toStr ?: ""
    clazz = map["class"]?.toStr ?: ""
    file = map["file"]?.toStr ?: ""
    line = map["line"]?.toStr ?: ""
    doc = map["doc"]?.toStr ?: ""
    sig = toSig
  }

  private Str toSig()
  {
    if(type == "module")
      return "$name"
    else if(type == "class")
      return "$module::$name"
    else
    {
      if( ! clazz.isEmpty)
        return "$module::${clazz}.$name"
      else
        return "${module}.$name"
    }
  }
}

