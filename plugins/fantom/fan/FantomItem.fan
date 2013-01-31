// History:
//  Jan 04 13 tcolar Creation
//

using camembert

**
** FantomItem
**
@Serializable
class FantomItem : FileItem
{
  PodInfo? pod
  PodGroup? group
  TypeInfo? type
  SlotInfo? slot

  new makePod(PodInfo p) : super.makeProject(p.srcDir)
  {
    this.icon = Sys.cur.theme.iconPod
    this.pod =  p
  }

  new makeGroup(PodGroup g) : super.makeProject(g.srcDir)
  {
    this.icon = Sys.cur.theme.iconPodGroup
    this.group =  g
  }

  new makeType(TypeInfo t, Str name := t.qname) : super.makeFile(t.toFile)
  {
    this.dis = name
    this.icon = Sys.cur.theme.iconType
    this.pod =  t.pod
    this.type = t
    this.loc = ItemLoc{it.line = t.line}
  }

  new makeSlot(SlotInfo s, Str name := s.qname) : super.makeFile(s.type.toFile)
  {
    this.dis = name
    this.indent = 1
    this.icon = (s is FieldInfo) ? Sys.cur.theme.iconField : Sys.cur.theme.iconMethod
    this.pod =  s.type.pod
    this.type = s.type
    this.slot = s
    this.loc = ItemLoc{it.line = s.line; it.col = 2}
  }
}