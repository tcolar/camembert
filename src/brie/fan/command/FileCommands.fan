using fwt
using netColarUtils

**************************************************************************
** ExitCmd
**************************************************************************

internal const class ExitCmd : Cmd
{
  override const Str name := "Exit"

  override Void invoke(Event event)
  {
    r := Dialog.openQuestion(frame, "Exit application?", null, Dialog.okCancel)
    if (r != Dialog.ok)
      return
    frame.saveSession
    Env.cur.exit(0)
  }
  new make(|This| f) {f(this)}
}

**************************************************************************
** ReloadCmd : reload cur file
**************************************************************************
internal const class ReloadCmd : Cmd
{
  override const Str name := "Reload"
  override Void invoke(Event event) { frame.curSpace.refresh }
  new make(|This| f) {f(this)}
}

**************************************************************************
** SaveCmd
**************************************************************************

internal const class SaveCmd : Cmd
{
  override const Str name := "Save"
  override Void invoke(Event event) { frame.save }
  new make(|This| f) {f(this)}
}

**************************************************************************
** New file
**************************************************************************
const class NewFileCmd : Cmd
{
  override const Str name := "New File / Folder"
  override Void invoke(Event event)
  {
    newFile(frame.curFile?.parent, "NewFile.fan", frame)
  }

  Void newFile(File? dir, Str filename, Frame frame)
  {
    Template[] tpls := [Template{it.name = "Empty file"; it.text=""}]
    tpls.addAll(Sys.cur.templates)

    LicenseTpl[] licenses := [LicenseTpl{it.name = "None"; it.text=""}]
    licenses.addAll(Sys.cur.licenses)

    ok := Dialog.ok
    cancel := Dialog.cancel

    name := Text {text = filename; prefCols = 60}

    tplCombo := Combo{items = tpls.map {it.name}}
    licCombo := Combo{items = licenses.map {it.name}}

    if(frame.lastLicense != null)
      licCombo.selected = frame.lastLicense

    path := Text
    {
      prefCols = 60
      text = (dir?.osPath ?: Env.cur.workDir.osPath) + File.sep
    }

    name.onKeyUp.add |Event e| {adjustCombo(tpls, tplCombo, name)}

    adjustCombo(tpls, tplCombo, name) // preselect item according to default file name

    dialog := Dialog(frame)
    {
      title = "New File"
      commands = [ok, cancel]
      body = GridPane
      {
        Label{ text = "New File Name:" },
        name,
        Label{ text = "Folder: (Any new folders will get created automatically)" },
        path,
        Label{ text = "License:" },
        licCombo,
        Label{ text = "Template:" },
        tplCombo,
      }
    }
    // Note: select is not working for some reason
    name.select(0, filename.index(".") ?: filename.size - 1)
    name.focus

    // open dialog
    if (dialog.open != Dialog.ok) return

    uri := File.os(path.text).normalize.uri
    FileUtils.mkDirs(uri)

    f := File.os(path.text).createFile(name.text)

    text := licenses.find {it.name == licCombo.selected}.text +
      tpls.find{it.name == tplCombo.selected}.text
        .replace("{date}", DateTime.now.toLocale("MMM DD YY"))
        .replace("{name}", f.basename)
        .replace("{user}", Env.cur.user)
        .replace("{folder}", dir?.name ?: "")

    f.out.print(text).close

    // store last license used in session, so we reuse the same until changed
    frame.lastLicense = licCombo.selected

    frame.curSpace.nav?.refresh(f.parent)
    frame.goto(FileItem.makeFile(f))
  }

  internal Void adjustCombo(Template[] tpls, Combo combo, Text text)
  {
    name := text.text
    ext := (name.contains(".") ? name[name.index(".") .. -1] : ".")[1 .. -1]
    tpl := tpls.find {it.extensions.contains(ext)}
    if(tpl != null)
      combo.selected = tpl.name
    else
      combo.selected = combo.items[0] // empty file tpl
  }

  new make(|This| f) {f(this)}
}

**************************************************************************
** Move / rename file
**************************************************************************
const class MoveFileCmd : Cmd
{
  override const Str name := "Move / Rename File"
  override Void invoke(Event event)
  {
    // contextual only for now
  }

  Void moveFile(File file, Frame frame)
  {
    ok := Dialog.ok
    cancel := Dialog.cancel
    name := Text {text = file.name; prefCols = 60}
    path := Text
    {
      prefCols = 60
      text = file.parent.osPath + File.sep
    }

    dialog := Dialog(frame)
    {
      title = "Move File"
      commands = [ok, cancel]
      body = GridPane
      {
        Label{ text = "File Name:" },
        name,
        Label{ text = "Folder: (Any new folders will get created automatically)" },
        path,
      }
    }
    name.focus

    // open dialog
    if (dialog.open != Dialog.ok) return

    uri := File.os(path.text).normalize.uri
    FileUtils.mkDirs(uri)

    dest := uri.plusSlash + name.text.toUri
    if(file.isDir)
      dest = dest.plusSlash
    to := (File(dest)).normalize
    file.moveTo(to)

    frame.curSpace.nav?.refresh(file.parent)
    frame.curSpace.nav?.refresh(to.parent)
    frame.goto(FileItem.makeFile(to))
  }
  new make(|This| f) {f(this)}
}

**************************************************************************
** Delete file
**************************************************************************
const class DeleteFileCmd : Cmd
{
  override const Str name := "Delete File / Folder"
  override Void invoke(Event event)
  {
    // only used contextually. for now anyway
  }

  Void delFile(File file, Frame frame)
  {
    r := Dialog.openQuestion(frame, "Delete $file.name ?", "Full path : $file.pathStr", Dialog.okCancel)

    if (r != Dialog.ok) return

    file.delete

    frame.curSpace.nav?.refresh(file.parent)

    //if cur file was deleted, got to any prev still present in history
    if(! frame.curFile.exists)
    {
      history := frame.history.items
      while(! history.isEmpty && ! history[0].file.exists)
        history.removeAt(0)

      frame.recentPane.update(frame.history)

      frame.goto(history[0])
    }
  }
  new make(|This| f) {f(this)}
}

internal const class OpenFolderCmd : Cmd
{
  override const Str name := "Open Folder"
  override Void invoke(Event event)
  {
    File? f := FileDialog
    {
      mode = FileDialogMode.openDir
    }.open(frame)

    if(f!=null)
      frame.goto(FileItem.makeFile(f))
  }
  new make(|This| f) {f(this)}
}

const class MarkAsProjectCmd : Cmd
{
  override const Str name := "Mark folder as project"
  override Void invoke(Event event)
  {
    // only used contextually. for now anyway
  }

  Void markAsProject(File file, Frame frame)
  {
    items := [,]
    PluginManager.cur.plugins.vals.sort|a, b|{a.name.lower <=> b.name.lower}.each |p| {
      items.add(p.name)
    }
    plugins := Combo{ it.items = items}
    dialog := Dialog(frame)
    {
      title = "Mark as project"
      commands = [ok, cancel]
      body = GridPane
      {
        Label{ text = "Project Type:" },
        plugins,
      }
    }

    if (dialog.open != Dialog.ok) return

    camFile := file + `cam.props`
    buf := camFile.open
    buf.printLine("prj.type = ${plugins.selected}")
    buf.close

    // Register the new proect and open it asap.
    ProjectRegistry.register(camFile.uri)
    ProjectRegistry.scan
    frame.goto(FileItem.makeProject(camFile))
  }

  new make(|This| f) {f(this)}
}