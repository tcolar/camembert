# History: Mar 20 13 Thibaut Colar Creation

"""
  Get members and documentation info about all known python modules without
  loading them.

  If called as a script the data is written in JSON format to the given file
  so it's usable externally.

  We get info and docs for modules, classes, functions.

  Fot the builtin modules we use inspect as it's safe in that case (+ no sources)

  For all other modules we use custom AST parsing because inspect can have side
  effects or even cause crashes

  Should be compatible with both Python 2 & 3

  Notes:
  Would have use pyclbr but unfortunately it does not provide easy access
  to docstrings.

  Also considered the pydoc utility but that generates some hardcoded 90's style
  HTML pages that we could not do much with.
"""

import ast
import os
import json
import sys
import imp
import inspect
import pkgutil
import io

class Visitor(ast.NodeVisitor):
  '''Modules AST visitor. Builds a list of items (modules, classes, functions)'''

  # all items found across all modules
  items = []

  # current file, node, class
  module = None
  file = None
  clazz = None

  def set_module(self, name, file):
    self.module = name
    self.clazz = None
    self.file = file

  # TODO : follow imports ??
  #def visit_ImportFrom(delf, node):
  #  print ast.dump(node)

  def generic_visit(self, node):
    ast.NodeVisitor.generic_visit(self, node)

  def visit_Module(self, node):
    self.items.append({"type":"module", "name" : self.module,
                "doc" : ast.get_docstring(node), "file": self.file, "line" : 1})

    ast.NodeVisitor.generic_visit(self, node)

  def visit_ClassDef(self, node):
    self.items.append({"type":"class", "name" : node.name, "module" : self.module,
                 "doc" : ast.get_docstring(node), "file": self.file, "line" : node.lineno})

    self.clazz = node.name
    ast.NodeVisitor.generic_visit(self, node)
    self.clazz = ""

  def visit_FunctionDef(self, node):
    self.items.append({"type":"function", "name" : node.name, "class" : self.clazz,
                "module" : self.module, "doc" : ast.get_docstring(node),
                "file": self.file, "line" : node.lineno})


def find_items():
  '''
  Return a list of all found items(dictionaries) for modules, classes, functions

  Module item keys: type, name, doc, file, line
  Class item keys: type, name, doc, file, line, module
  Function/Method item keys: type, name, doc, file, line, class, module
  '''

  visitor = Visitor()
  items = []

  # First we do the builtin modules, we use inspect for those as we don't have
  # the sources since it's in C. Those are already loaded and safe to inspect anyway

  for module in sys.builtin_module_names:
    # Note: No need to import the module since it's a builtin
    for name, member in inspect.getmembers(module):
      if inspect.ismodule(member):
        items.append({"type":"module", "name" : module,
              "doc" : inspect.getdoc(member), "file": None, "line" : 0})
      elif inspect.isbuiltin(member):
        items.append({"type":"function", "name" : name,
              "module" : module, "class" : None,
              "doc" : inspect.getdoc(member), "file": None, "line" : 0})
      # Doesn't seem there is such thing as classes in builtin modules

  # Now we do all other modules, for those we use AST parsing because inspect
  # would require loading them which can cause side effects and crashes

  for importer, name, ispkg in pkgutil.iter_modules():
    loader = importer.find_module(name)

    src = None
    if hasattr(loader,'get_filename'):
      file = os.path.abspath(loader.get_filename())

    if hasattr(loader,'get_source'):
       src = loader.get_source(name)
    elif file != None:
       if file.endswith(".py"):
         with open(loader.get_filename(name), "r") as f:
           src = f.read()

    if src != None :
      try:
        root = ast.parse(src)
        visitor.set_module(name, file)
        visitor.visit(root)
      except TypeError:
        print("failed parsing module " + name)

  items.extend(visitor.items)

  return items


# Script Main -----------------------------------

if __name__ == "__main__":

  if len(sys.argv) < 2:
    print("Error, Expecting destination file path as an argument !")
    sys.exit(-1)

  dest = sys.argv[1]

  items = find_items()

  text = json.dumps(items, indent=1) + "\n"

  out = open(dest, "w")
  out.write(text)
  out.close

