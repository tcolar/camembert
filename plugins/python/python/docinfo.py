# History: Mar 20 13 Thibaut Colar Creation

"""
  Get members and documentation info about all known python modules.

  If called as a script the data is written in JSON format to the given file
  so it's usable externally.

  We get info and docs for modules, classes, functions.

  We rely on the inspect module (loads the modules to get info !)

"""

import json
import sys
import inspect
import pkgutil
import io
import subprocess

# Easter egg modules we don't want to load .. only funny a couple times ;)
easter_modules = ["this", "antigravity"]

def find_items():
  '''
  Return a list of all found items(dictionaries) for modules, classes, functions

  Module item keys: type, name, doc, file, line
  Class item keys: type, name, doc, file, line, module
  Function/Method item keys: type, name, doc, file, line, class, module
  '''

  items = []

  modules = []

  for (module_loader, name, ispkg) in pkgutil.iter_modules():

    if name in easter_modules:
      continue

    try:
      found = module_loader.find_module(name)

      # we try first to import it in a subprocess, this is much slower
      # but saves us if loading the module segfaults, which can happen

      # Unfortunately does not always work because sometimes module combination causes the crash
      # python 2.7 on ubuntu = fail !
      # ie : https://bugs.launchpad.net/ubuntu/+bug/1028625
      subprocess.check_call(["python","-c","import imp;imp.load_module('"+name+"', * imp.find_module('"+name+"'))"])

      # Ok, it didn't completely fail, then load it "in process"
      module = found.load_module(name)

      # Ok, loaded ok, add it to "good" modules list
      modules.append(module)

    except ImportError:
      print("Failed finding : " + name)
    except TypeError:
      print("Failed loading : " + name)
    except subprocess.CalledProcessError:
      print("Could not load module " + name)

  # add builtins
  modules.extend(sys.builtin_module_names)

  # Ok, no inspect the good modules and build our items list (members info)
  for module in modules:

    for name, member in inspect.getmembers(module):
      # Note: calling getfile on builtin module raise an error on 3.x even thugh doc says it should not
      modname = None
      file = None
      try:
        file = inspect.getfile(member)
        modname = module.__name__
      except TypeError:
        pass
      if inspect.ismodule(member):
        items.append({"type": "module", "name" : name,
              "doc" : inspect.getdoc(member), "file": file, "line" : 0})
      elif inspect.isclass(member):
        items.append({"type":"class", "name" : name,
              "module" : modname, "class" : None,
              "doc" : inspect.getdoc(member), "file":  file, "line" : 0})
      elif inspect.isfunction(member):
        items.append({"type":"function", "name" : name,
              "module" : modname, "class" : None,
              "doc" : inspect.getdoc(member), "file":  file, "line" : 0})
      elif inspect.isbuiltin(member):
        items.append({"type":"function", "name" : name,
              "module" : modname, "class" : None,
              "doc" : inspect.getdoc(member), "file":  None, "line" : 0})
      elif inspect.ismethod(member):
        items.append({"type":"function", "name" : name,
              "module" : modname, "class" : None, #member.im_class,
              "doc" : inspect.getdoc(member), "file":  file, "line" : 0})

  return items


# Script Main -----------------------------------

if __name__ == "__main__":
  print(sys.executable)

  if len(sys.argv) < 2:
    print("Error, Expecting destination file path as an argument !")
    sys.exit(-1)

  dest = sys.argv[1]

  items = find_items()

  text = json.dumps(items, indent=1) + "\n"

  out = open(dest, "w")
  out.write(text)
  out.close

