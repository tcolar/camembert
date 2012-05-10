//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Aug 12  Brian Frank  Creation
//

using gfx
using fwt

**
** Console prompt text field
**
class Prompt : ContentPane
{

  new make(App app, Console console)
  {
    this.app = app
    this.console = console
    this.field = Text
    {
      it.text   = "console"
      it.fg     = Theme.div
      it.font   = app.options.font
      it.border = false
      it.onFocus.add   |e| { onTextFocus(e) }
      it.onBlur.add    |e| { onTextBlur(e) }
      it.onModify.add  |e| { onTextModify(e) }
      it.onAction.add  |e| { onTextAction(e) }
      it.onKeyDown.add |e| { onTextKeyDown(e) }
    }
    this.content = BorderPane
    {
      it.bg = app.options.bg
      it.insets = Insets(10, 10, 0, 10)
      it.content = BorderPane
      {
        it.border = Border("2 $Theme.div")
        it.content = field
      }
    }
  }

  Void onTextFocus(Event event)
  {
    field.text = ""
    field.fg = Color.black
    focused = true
    console.typing("")
  }

  Void onTextBlur(Event event)
  {
    focused = false
    field.text = "console"
    field.fg = Theme.div
  }

  Void onTextAction(Event event)
  {
    console.run(field.text)
  }

  Void onTextKeyDown(Event event)
  {
    switch (event.key.toStr)
    {
      case "Down": event.consume; console.lister.focus; return
      default:     app.controller.onKeyDown(event)
    }
  }

  Void onTextModify(Event event)
  {
    if (focused) console.typing(field.text)
  }

  App app
  Console console
  Text field
  Bool focused
}


