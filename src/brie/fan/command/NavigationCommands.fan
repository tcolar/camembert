
using fwt
using gfx
using petanque
using concurrent


**************************************************************************
** Recent
**************************************************************************

internal const class RecentCmd : Cmd
{
  override const Str name := "Recent"
  override const Key? key := Key("Ctrl+Space")
  override Void invoke(Event event)
  {
    Dialog? dlg
    picker := HistoryPicker(frame.history.items) |item, e|
    {
      frame.goto(item)
      dlg.close
    }
    pane := ConstraintPane { minw = 300; maxh = 300; add(picker) }
    dlg = Dialog(frame) { title="Recent"; body=pane; commands=[Dialog.ok, Dialog.cancel] }
    dlg.open
  }
}

**************************************************************************
** Prev/Next Mark
**************************************************************************

internal const class PrevMarkCmd : Cmd
{
  override const Str name := "Prev Mark"
  override const Key? key := Key("Shift+F8")
  override Void invoke(Event event) { frame.curMark-- }
}

internal const class NextMarkCmd : Cmd
{
  override const Str name := "Next Mark"
  override const Key? key := Key("F8")
  override Void invoke(Event event) { frame.curMark++ }
}

**************************************************************************
** GotoCmd
**************************************************************************

internal const class GotoCmd : Cmd
{
  override const Str name := "Goto"
  override const Key? key := Key("Ctrl+G")
  override Void invoke(Event event)
  {
    // prompt field
    font :=  ((Sys)Service.find(Sys#)).theme.font
    prompt := Text
    {
      it.font = font
    }

    // table of matches
    matches := GotoMatchModel { itemFont = font; width = 500 }

    
    table := Table
    {
      it.headerVisible = false
      it.model = matches
    }

    // check for current selection to initialize
    selection := frame.curView?.curSelection ?: ""
    prompt.text = selection
    
    // If selection & single match, no need to prompt, just go straight there
    if(! selection.isEmpty)
    {
      matches.items = findMatches(prompt.text.trim)
      if(matches.items.size == 1)
      {
        frame.goto(matches.items.first)
        return
      }  
    }

    // build dialog
    Item? selected
    ok := Dialog.ok
    cancel := Dialog.cancel
    dialog := Dialog(frame)
    {
      title = "Goto"
      commands = [ok, cancel]
      body = EdgePane
      {
        top = InsetPane(0, 0, 10, 0) { prompt, }
        bottom = ConstraintPane
        {
          minw = maxw = matches.width+10
          minh = maxh = 500
          table,
        }
      }
    }
    prompt.onAction.add |e| { dialog.close(ok) }
    prompt.onKeyDown.add |e|
    {
      if (e.key == Key.down)
      {
        e.consume
        if (table.model.numRows > 0) table.selected = [0]
          table.focus
      }
    }
    prompt.onModify.add |e|
    {
      matches.items = findMatches(prompt.text.trim)
      table.refreshAll
    }
    table
    {
      onAction.add |e|
      {
        selected = matches.items.getSafe(table.selected.first ?: -1)
        dialog.close(ok)
      }
    }

    // open dialog
    if (dialog.open != Dialog.ok) return

      // if we got actual selection from table use that
    // otherwise assume top match from table
    if (selected == null) selected = matches.items.first
      if (selected == null) return
      frame.goto(selected)
  }

  private Item[] findMatches(Str text)
  {
    acc := Item[,]

    // integers are always line numbers
    line := text.toInt(10, false)
    file := frame.curFile
    if (line != null && file != null)
      return [Item { it.dis= "Line $line"; it.file = file; it.line = line-1 }]

    /// slots in current type
    curType := frame.curSpace.curType
    if (curType != null)
    {
      curType.slots.each |s|
      {
        if (s.name.startsWith(text)) acc.add(Item(s) { dis = s.name })
        }
    }

    // match types
    if (!text.isEmpty)
      acc.addAll(sys.index.matchTypes(text).map |t->Item| { Item(t) })

    // f <file>
    if (text.startsWith("f ") && text.size >= 3)
      acc.addAll(sys.index.matchFiles(text[2..-1]))

    return acc
  }
}

internal class GotoMatchModel : TableModel
{
  Font? itemFont
  Int width
  Item[] items := Item[,]

  override Int numRows() { items.size }
  override Int numCols() { 1 }
  override Str header(Int col) { "" }
  override Str text(Int col, Int row) { items[row].dis }
  override Image? image(Int col, Int row) { items[row].icon }
  override Font? font(Int col, Int row) { itemFont }
  override Int? prefWidth(Int col) { width }
}

**************************************************************************
** FindCmd
**************************************************************************

internal const class FindCmd : Cmd
{
  override const Str name := "Find"
  override const Key? key := Key("Ctrl+F")
  override Void invoke(Event event)
  {
    f := frame.curFile
    if (f != null) find(f)
    }

  Void find(File file)
  {
    prompt := Text { }
    path := Text { text = FileUtil.pathDis(file) }
    matchCase := Button { mode = ButtonMode.check; text = "Match case"; selected = lastMatchCase.val }

    selection := frame.curView?.curSelection ?: ""
    if (!selection.isEmpty && !selection.contains("\n"))
      prompt.text = selection.trim
    else
      prompt.text = lastStr.val

    pane := GridPane
    {
      numCols = 2
      expandCol = 1
      halignCells = Halign.fill
      Label { text="Find" },
      ConstraintPane { minw=300; maxw=300; add(prompt) },
      Label { text="File" },
      ConstraintPane { minw=300; maxw=300; add(path) },
      Label {}, // spacer
      matchCase,
    }
    dlg := Dialog(frame)
    {
      title = "Find"
      body  = pane
      commands = [Dialog.ok, Dialog.cancel]
    }
    prompt.onAction.add |->| { dlg.close(Dialog.ok) }
    if (Dialog.ok != dlg.open) return

      // get and save text to search for
    str := prompt.text
    lastStr.val = str
    lastMatchCase.val = matchCase.selected

    // find all matches
    matches := Item[,]
    if (!matchCase.selected) str = str.lower
      findMatches(matches, file, str, matchCase.selected)
    if (matches.isEmpty) { Dialog.openInfo(frame, "No matches: $str.toCode"); return }

      // open in console
    console.show(matches)
    frame.goto(matches.first)
  }

  Void findMatches(Item[] matches, File f, Str str, Bool matchCase)
  {
    // recurse dirs
    if (f.isDir)
    {
      if (f.name.startsWith(".")) return
        if (f.name == "tmp" || f.name == "temp") return
        f.list.each |x| { findMatches(matches, x, str, matchCase) }
      return
    }

    // skip non-text files
    if (f.mimeType?.mediaType != "text") return

      f.readAllLines.each |line, linei|
    {
      chars := matchCase ? line : line.lower
      col := chars.index(str)
      while (col != null)
      {
        dis := "$f.name(${linei+1}): $line.trim"
        span := Span(linei, col, linei, col+str.size)
        matches.add(Item(f)
          {
            it.line = linei
            it.col  = col
            it.span = span
            it.dis  = dis
            it.icon = this.sys.theme.iconMark
          })
        col = chars.index(str, col+str.size)
      }
    }
  }

  const AtomicRef lastStr := AtomicRef("")
  const AtomicBool lastMatchCase:= AtomicBool(true)
}

**************************************************************************
** FindInSpaceCmd
**************************************************************************

internal const class FindInSpaceCmd : Cmd
{
  override const Str name := "Find in Space"
  override const Key? key := Key("Shift+Ctrl+F")
  override Void invoke(Event event)
  {
    File? dir
    cs := frame.curSpace
    if (cs is PodSpace)  dir = ((PodSpace)cs).dir
      if (cs is FileSpace) dir = ((FileSpace)cs).dir
      if (dir != null) ((FindCmd)sys.commands.find).find(dir)
    }
}