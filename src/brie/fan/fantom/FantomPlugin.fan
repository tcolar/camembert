// History:
//  Jan 05 13 tcolar Creation
//

using gfx
using netColarUtils

**
** FantomPlugin
** Builtin plugin for fantom features
**
const class FantomPlugin : Plugin
{
  override Void onInit(File configDir)
  {
    // Create templates if missing
    fanClass := configDir + `templates/fantom_class.json`
    if( ! fanClass.exists)
      JsonUtils.save(fanClass.out, Template{it.name="Fantom class"; it.order = 3
        it.extensions=["fan","fwt"]
        it.text="// History:\n//  {date} {user} Creation\n//\n\n**\n** {name}\n**\nclass {name}\n{\n}\n"})

    fanMixin := configDir + `templates/fantom_mixin.json`
    if( ! fanMixin.exists)
      JsonUtils.save(fanMixin.out, Template{it.name="Fantom mixin"; it.order = 13
        it.text="// History:\n//  {date} {user} Creation\n//\n\n**\n** {name}\n**\nmixin {name}\n{\n}\n"})

    fanEnum := configDir + `templates/fantom_enum.json`
    if( ! fanEnum.exists)
      JsonUtils.save(fanEnum.out, Template{it.name="Fantom enum"; it.order = 23
        it.text="// History:\n//  {date} {user} Creation\n//\n\n**\n** {name}\n**\nenum class {name}\n{\n}\n"})

    licenses := configDir + `licenses/default.json`
    if( ! licenses.exists)
      JsonUtils.save(licenses.out, License{it.name="default"
        it.text="// Copyright 2013 : me - Change this and create new licenses in config/licenses/\n//\n"})

    // TODO: init index and so on here
  }

  override Void onFrameReady(Frame frame)
  {
    // todo : start indexer etc ...
  }

  override FileItem[] projects()
  {
    FileItem[] items := [,]
    // pod groups
    Sys.cur.index.groups.each
    {
      path := groupPath(it)[0..-2]
      indent := 0 ; path.chars.each {if(it == '/') indent++}
      items.add(FileItem.makeProject(it.srcDir, indent, path).setDis(it.name))
    }
    // pods
    Sys.cur.index.pods.each
    {
      if(srcDir != null)
      {
        path := podPath(it)
        indent := 0 ; path.chars.each {if(it == '/') indent++}
        items.add(FileItem.makeProject(it.srcDir, indent, path).setDis(it.name))
      }
    }
    return items
  }

  private Str podPath(PodInfo pi)
  {
    return groupPath(pi.group) + pi.name
  }

  private Str groupPath(PodGroup? group)
  {
    path := ""
    while(group != null)
    {
      path = "${group.name}/$path"
      group = group.parent
    }
    return path
  }

  override Space? createSpace(File file)
  {
    if(file.isDir)
    {
      group := Sys.cur.index.isGroupDir(file)
      if(group != null)
        return FantomSpace(Sys.cur.frame, group.name, file)
      pod := Sys.cur.index.isPodDir(file)
      if(pod != null)
        return FantomSpace(Sys.cur.frame, pod.name, file)
    }
    return null
  }

  override Int spacePriority(File prjDir)
  {
    pod := Sys.cur.index.isPodDir(prjDir)
    if(pod != null)
      return 55
    group := Sys.cur.index.isGroupDir(prjDir)
    if(group != null)
      return 50
    return 0
  }

  override Image? iconForFile(File file)
  {
    if(file.isDir)
    {
      pod := Sys.cur.index.isPodDir(file)
      if(pod != null)
        return Sys.cur.theme.iconPod
      group := Sys.cur.index.isGroupDir(file)
      if(group != null)
        return Sys.cur.theme.iconPodGroup
    }
    // fantom files handled by standard Theme code
    return null
  }

  override Void onShutdown()
  {
  }
}