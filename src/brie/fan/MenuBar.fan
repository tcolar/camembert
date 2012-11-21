// History:
//   11 8 12 Creation
using fwt

**
** MenuBar
**
class MenuBar : Menu
{
  Menu file
  Menu nav
  Menu process
  Menu panels
  Menu options

  new make(Sys sys)
  {
      file = Menu {
        it.text = "File"
        MenuItem{ it.command = sys.commands.save.asCommand},
        MenuItem{ it.command = sys.commands.newFile.asCommand},
        MenuItem{ it.command = sys.commands.openFolder.asCommand},
        MenuItem{ it.command = sys.commands.reload.asCommand},
        MenuItem{ it.command = sys.commands.exit.asCommand},
      }

      nav = Menu {
        it.text = "Navigation"
        MenuItem{ it.command = sys.commands.searchDocs.asCommand},
        MenuItem{ it.command = sys.commands.mostRecent.asCommand},
        MenuItem{ it.command = sys.commands.find.asCommand},
        MenuItem{ it.command = sys.commands.findInSpace.asCommand},
        MenuItem{ it.command = sys.commands.goto.asCommand},
        MenuItem{ it.command = sys.commands.prevMark.asCommand},
        MenuItem{ it.command = sys.commands.nextMark.asCommand},
      }

      process = Menu {
        it.text = "Process"
        MenuItem{ it.command = sys.commands.build.asCommand},
        MenuItem{ it.command = sys.commands.buildGroup.asCommand},
        MenuItem{ it.command = sys.commands.run.asCommand},
        MenuItem{ it.command = sys.commands.buildAndRun.asCommand},
        MenuItem{ it.command = sys.commands.terminate.asCommand},
      }

      panels = Menu {
        it.text = "Panels"
        MenuItem{ it.command = sys.commands.consoleToggle.asCommand},
        MenuItem{ it.command = sys.commands.docsToggle.asCommand},
        MenuItem{ it.command = sys.commands.recentToggle.asCommand},
      }


      configs := Menu{
        it.text = "Switch config"
          MenuItem{ it.command = SwitchConfigCmd("default", Options.standard).asCommand
                    it.mode = MenuItemMode.radio
                    it.selected = true
                  },
      }
      sys.configs.each |file, name|
      {
        configs.add(MenuItem{
          it.command = SwitchConfigCmd(name, file).asCommand; it.mode = MenuItemMode.radio
        })
      }

      options = Menu {
        it.text = "Options"
        MenuItem{ it.command = sys.commands.editConfig.asCommand},
        MenuItem{ it.command = sys.commands.reloadConfig.asCommand},
        configs,
      }

      add(file)
      add(nav)
      add(process)
      add(panels)
      add(options)
    }
}