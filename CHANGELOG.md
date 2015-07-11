## 0.1.4 - Feature
  A new feature where the package now measures how many steps into the path
  the source and the header shares and when multiple files match the file name it now selects the one closest to the triggering file. (For multiple projects in the same window/workspace with for example main.cc and main.h in each project)

## 0.1.3 - Bugfix
  A bug were when the editor was destroyed non saved changes were also destroyed
  the fix now saves files through TextEditor::Save() before destroying.

## 0.1.2 - Bugfixes
  A bug were toggling the program with a source or a header selected sent the
  package into an unbreakable loop has been fixed.
  Also a bug which increased the number of calls to functions has been resolved

## 0.1.1 - Patch
  Added protection against crashing with untitled files.

## 0.1.0 - First Release
  Activate with ctrl-alt-o (toggle)
  Open a panes to the right with the counterpart-file.
  Manages it's files, i.e closes files it has itself opened.
