using fwt

**************************************************************************
** EscCmd
**************************************************************************

internal const class EscCmd : Cmd
{
  override const Str name := "Esc"
  override const Key? key := Key("Esc")
  override Void invoke(Event event)
  {
    frame.marks = Item[,]
    frame.console.close
    frame.curView?.onReady
  }
}

**************************************************************************
** BuildCmd
**************************************************************************

internal const class BuildCmd : Cmd
{
  override const Str name := "Build"
  override const Key? key := Key("F9")
  override Void invoke(Event event)
  {
    f := findBuildFile
    if (f == null)
    {
      Dialog.openErr(frame, "No build.fan file found")
      return
    }


    console.execFan([f.osPath], f.parent) |c|
    {
      pod := sys.index.podForFile(f)
      if (pod != null) sys.index.reindexPod(pod)
      }
  }

  File? findBuildFile()
  {
    // save current file
    frame.save

    // get the current resource as a file, if this file is
    // the build.fan file itself, then we're done
    f := frame.curFile
    if (f == null) return null
      if (f.name == "build.fan") return f

      // lookup up directory tree until we find "build.fan"
    if (!f.isDir) f = f.parent
      while (f.path.size > 0)
    {
      buildFile := f + `build.fan`
      if (buildFile.exists) return buildFile
        f = f.parent
    }
    return null
  }  
}
