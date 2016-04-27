## 0.4.0 - Destroy Empty Panes
  Option for destroying side pane when no counterpart found.
  This will reset the pane sizing on the next found counterpart.
  Disabled by default.

## 0.3.1 - Bugfix
  On Windows the package would not do anything. This was due to a bug in the closeness
  function. The closeness function is now modified slightly and is updating closest file
  even on a equal distance away. This for Windows essential mean there is no sense of distance
  and the last file searched (and matched) will be the file selected. Especially
  troublesome in large projects. The closeness function will be suitably updated
  for windows release at a future date.

## 0.3.0 - Readme update
  Updated the readme to better reflect the workings of the current version

## 0.2.0 - Feature
  RegExp for extensions are now configurable from atom config.

## 0.1.5 - Bugfix
  Using the synchronous version of the tree traversal
  led to a EPERM error. This patch switches to the asynchronous version.

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
