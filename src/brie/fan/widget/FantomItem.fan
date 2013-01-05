// History:
//  Jan 04 13 tcolar Creation
//

**
** FantomItem
**
const class FantomItem : FileItem
{
  const PodInfo? pod
  const TypeInfo? type
  const SlotInfo? slot
  const Str? group

  private new make(|This|? f) : super(f)
  {
  }

  static FantomItem forPod(PodInfo p, Str? dis := null, Int indent := 0)
  {
    FantomItem
    {
      it.indent = indent
      it.dis  = dis ?: p.name
      it.icon = Sys.cur.theme.iconPod
      it.file = FileUtil.findBuildPod(p.srcDir, p.srcDir)
      it.isProject = true
      it.pod  = p
    }
  }

  static FantomItem forGroup(PodGroup g, Str? dis := null, Int indent := 0)
  {
    FantomItem
    {
      it.indent = indent
      it.dis  = dis ?: g.name
      it.icon = Sys.cur.theme.iconPodGroup
      it.file = g.srcDir
      it.isProject = true
      it.group = g.name
    }
  }

  static FantomItem forType(TypeInfo t, Str? dis := null, Int indent := 0)
  {
    FantomItem
    {
      it.indent = indent
      it.dis  = dis ?: t.qname
      it.icon = Sys.cur.theme.iconType
      it.file = t.toFile
      it.loc = ItemLoc{it.line = t.line}
      it.pod  = t.pod
      it.type = t
    }
  }

  static FantomItem forSlot(SlotInfo s, Str? dis := null, Int indent := 0)
  {
    FantomItem
    {
      it.indent = indent
      it.dis  = dis ?: s.qname
      it.icon = s is FieldInfo ? Sys.cur.theme.iconField : Sys.cur.theme.iconMethod
      it.file = s.type.toFile
      it.loc = ItemLoc{it.line = s.line; it.col = 2}
      it.pod  = s.type.pod
      it.type = s.type
      it.slot = s
    }
  }
}