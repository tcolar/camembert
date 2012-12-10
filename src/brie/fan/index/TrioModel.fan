// History:
//   12 7 12 Creation

**
** Trio tag/funcs info of a pod
**
const class TrioInfo
{
  new make(Str pod, Str:TagInfo tags, Str:FuncInfo funcs)
  {
    this.tags = tags
    this.funcs = funcs
    this.pod = pod
  }

  const Str pod
  const Str:TagInfo tags
  const Str:FuncInfo funcs
}

**
** Model for trio function
**
const class FuncInfo
{
  const Str:Str data
  const Str pod

  new make(Str pod, Str:Str data) {this.data = data; this.pod = pod}

  Str name() {data["name"] ?: ""}
  Str doc() {data["doc"] ?: ""}
  Str src() {data["src"] ?: ""}

  ** Function signature ... not seing a tag fro that, so extracting from source
  Str sig()
  {
    src := data["src"]
    // probably dont need those checks but being safe
    if(src!=null && src.contains("=>"))
    {
      sig := src[0 ..< src.index("=>")]
      return "<b>${name}</b>${sig}"
    }
    else
     return "<b>${name}</b>(?)"
  }
}

**
** Model for trio tag
**
const class TagInfo
{
  const Str:Str data
  const Str pod

  new make(Str pod, Str:Str data) {this.data = data; this.pod = pod}

  Str name() {data["tag"] ?: ""}
  Str doc() {data["doc"] ?: ""}
  Str kind() {data["kind"] ?: ""}
}


