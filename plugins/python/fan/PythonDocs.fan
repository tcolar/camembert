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
  const AtomicRef isIndexing := AtomicRef(false)

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
    query = query.trim

    docs := _docs.val as Str:PythonDoc
    if(docs == null)
      return "Index not ready yet."

    if(query.isEmpty)
      return index(docs)

    // exact match
    if(docs.containsKey(query))
    {
      data := docs[query]
      if(data.type == "module")
      {
        result := "<h2>$data.name</h2><hr/>"
        docs.each
        {
          if(it.link.startsWith(query))
            result+= it.name + ", &nbsp;"
        }
        result += "<hr/>" + data.doc.replace("\n","<br/>")+"<hr/>"
        docs.each
        {
          if(it.link.startsWith(query))
            result+= "<br/><a name='$it.name'></a><div class='bg2'>$it.name</div>"
              + it.doc.replace("\n","<br/>")
        }
        return result
      }
    }

    // search
    result := ""
    docs.keys.each |key|
    {
      if(key.contains(query))
        result += "<a href='/camPythonPlugin/$key'>$key</a><br/>"
    }
    return result
  }

  ** Return python index (modules)
  Str index(Str:PythonDoc docs)
  {
    result := "<h2>Modules:</h2>"
    modules := docs.keys.findAll |Str key, Int index -> Bool|
    {
      return (! key.contains(".") && ! key.contains("#"))
    }
    modules.each |module|
    {
      result += "<a href='/camPythonPlugin/$module'>$module</a><br/>"
    }
    return result
  }

  Void clearIndex()
  {
    (Sys.cur.optionsFile.parent + `state/`).listFiles.each
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
    if(isIndexing.val)
      return // already indexing
    result := Actor(ActorPool(), |Obj? obj -> Obj?|
    {
      isIndexing.val = true
      try
      {
        config := PluginManager.cur.conf(dis) as BasicConfig
        if(config == null) {echo("Python indexing error: Missing config"); return null}
        env := config.curEnv as PythonEnv
        if(env == null)  {echo("Python indexing error: Missing env"); return null}
        python := env.python3Path.toFile
        if( ! python.exists)  {echo("Python indexing error: python3Path is not set properly in the python env !"); return null}

        version := runPython(python, ["--version"]).readAllStr
        if(version.size < 7) {return null}
        version = version[7 .. -1].trim

        info := Sys.cur.optionsFile.parent + `state/python_info_${version}.json`

        echo("Info: $info.osPath")

        if(! info.exists)
        {
          script := Sys.cur.optionsFile.parent + `Python/docinfo.py`
          Pod.of(this).file(`/python/docinfo.py`).copyTo(script, ["overwrite" : true])

          runPython(python, [script.osPath, info.osPath])
        }
        Obj? theDocs := JsonInStream(info.in).readJson

        _docs.val = scan(theDocs)
      }
      catch(Err e)
      {
        Sys.log.err("Failed loading Python docs !", e)
        e.trace
      }
      finally
      {
        isIndexing.val = false
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
      docs[doc.link] = doc
    }
    Str:PythonDoc sorted := [:] {ordered = true}

    docs.keys.sort.each {sorted[it] = docs[it]}

    return sorted.toImmutable
  }

  private Buf runPython(File python, Str[] args)
  {
    p := Process([python.osPath].addAll(args))
    b := Buf()
    p.err = b.out
    p.out = b.out
    id := Sys.cur.processManager.register(p, "Python")
    try
      p.run().join()
    finally
      Sys.cur.processManager.unregister(id)
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
  const Str link := ""

  new make(Str:Obj? map)
  {
    type = map["type"]?.toStr ?: ""
    name = map["name"]?.toStr ?: ""
    module = map["module"]?.toStr ?: ""
    clazz = map["class"]?.toStr ?: ""
    file = map["file"]?.toStr ?: ""
    line = map["line"]?.toStr ?: ""
    doc = map["doc"]?.toStr ?: ""
    link = toLink
  }

  private Str toLink()
  {
    if(type == "module")
      return "$name"
    else if(type == "class")
      return "${module}.{$name}"
    else
    {
      if( ! clazz.isEmpty)
        return "${module}.${clazz}#$name"
      else
        return "${module}#$name"
    }
  }
}

