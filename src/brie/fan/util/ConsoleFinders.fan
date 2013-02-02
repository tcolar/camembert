// History:
//  Feb 01 13 tcolar Creation
//

**
** LineParser
** Parsers for console output
**
const class ConsoleFinders
{
  // Javac  "file:col: msg"
  static const |Str -> Item?| fanFinder := |Str str-> Item?|
  {
    if(str.size < 4) return null
    p1 := str.index("(", 4); if (p1 == null) return null
    c  := str.index(",", p1); if (c == null) return null
    p2 := str.index(")", p1); if (p2 == null) return null
    if(p1 > c || c > p2) return null
    file := File.os(str[0..<p1])
    line := str[p1+1..<c].toInt(10, false) ?: 1
    col  := str[c+1..<p2].toInt(10, false) ?: 1
    text := file.name + str[p1..-1]
    return FileItem.makeFile(file).setDis(text).setLoc(
          ItemLoc{it.line = line-1; it.col  = col-1}).setIcon(
          Sys.cur.theme.iconErr)
  }

  // Fantom "file(line,col): msg"
  static const |Str -> Item?| javaFinder := |Str str-> Item?|
  {
    if(str.size < 4) return null
    c1 := str.index(":", 4); if (c1 == null) return null
    c2 := str.index(":", c1+1); if (c2 == null) return null
    file := File.os(str[0..<c1])
    if (!file.exists) return null
      line := str[c1+1..<c2].toInt(10, false) ?: 1
    text := file.name + str[c1..-1]
    return FileItem.makeFile(file).setDis(text).setLoc(ItemLoc {it.line = line-1})
            .setIcon(Sys.cur.theme.iconErr)
  }
}