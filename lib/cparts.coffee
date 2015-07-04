
{CompositeDisposable} = require 'atom'
{File} = require 'atom'
fs = require 'fs-plus'
toggleState = false
lastEditor = null
panes = null
main = null
counterpart = null


module.exports = Cparts =
  observePane: null
  commands: null
  destroyedPane: null
#-------------------------------------------------------------------

  activate: (state) ->
    @activateCommands()

#-------------------------------------------------------------------

  activateCommands: () ->
    @commands = CompositeDisposable
    console.debug "Activating commands "
    @commands = atom.commands.add 'atom-workspace', 'cparts:toggle': => @toggle()

#-------------------------------------------------------------------

  activatePane: () ->
    console.debug "Activating Pane"
    return unless panes = atom.workspace.getActivePane()
    @destroyedPane = panes.onDidDestroy => @paneDestroyed()
    @observePane = panes.observeActiveItem => @changedFile()
#-------------------------------------------------------------------

  deactivatePane: () ->
    #Stop tracking panes by disposing subscriptions
    console.debug "Deactivating pane"
    try
      @observePane.dispose()
      @destroyedPane.dispose()
    catch
      console.error "didn't dispose properly"
#-------------------------------------------------------------------

  deactivate: () ->
    #Make sure any pane exists.
    return unless pane = atom.workspace.getPanes()
    if lastEditor
      try
        lastEditor.destroy()
      catch
        console.debug "LastEditor.destroy issue in changedFile"
    lastEditor = null

#-------------------------------------------------------------------

  paneDestroyed: () ->
    console.debug "paneDestroyed"
    lastEditor = null
    @deactivatePane()
    @activatePane()

#-------------------------------------------------------------------

  toggle: () ->

    if toggleState
      toggleState = false;
      @deactivatePane()
      @deactivate()
      console.debug "toggle false"
    else
      toggleState = true;
      return unless panes = atom.workspace.getActivePane()
      @activatePane()
      console.debug "toggle true"

#-------------------------------------------------------------------

   searchHeader: (absPath) ->
     fileName = absPath.match /[^\\/]+$/
     noExt = fileName[0].replace /\.[^/.]+$/ , ""

     if main is noExt
       if absPath.match /\.(h|hh|HH|hpp|HPP)$/gim
         counterpart = absPath
         return true
     return true

#-------------------------------------------------------------------

    searchSource: (absPath) ->
      fileName = absPath.match /[^\\/]+$/
      noExt = fileName[0].replace /\.[^/.]+$/ , ""

      if main is noExt
        if absPath.match /\.(c|cc|cC|cpp|CPP)$/gim
          counterpart = absPath
          return true
      return true

#-------------------------------------------------------------------

  changedFile: () ->

    if not toggleState
      return
    #get editor and save previous active pane
    try
      return unless editor = panes.getActiveItem()
      editor.getPath() #call a editor member function to be certain (should be a typeof comparison)
    catch
      return

    previousActivePane = atom.workspace.getActivePane()

    return unless filePath = editor.getPath()

    return unless extension = filePath.match /\.[^/.]+$/
    if extension[0].match /\.(c|cc|cC|cpp|CPP)$/gim
      console.debug "source detected"
      main = editor.getTitle().replace /\.[^/.]+$/ , ""
      for path in atom.project.getPaths()
        fs.traverseTreeSync(path,@searchHeader)
      #try and find file with header extensions.
    else if extension[0].match /\.(h|hh|HH|hpp|HPP)$/gim
      console.debug "header detected"
      main = editor.getTitle().replace /\.[^/.]+$/ , ""
      for path in atom.project.getPaths()
        fs.traverseTreeSync(path,@searchSource)
      #try and find file with source extensions.
    else
      return

    #Create editor uri
    uri = "cparts://editor/#{editor.id}"

    #Ensure existence of file.
    file = new File(counterpart,false)
    if not file.existsSync()
      return

    fileOptions =
      searchAllPanes: false
      split:'right'

    #Recieve texteditor promise and destroy lastEditor
    atom.workspace.open(counterpart, fileOptions).done (newEditor) ->
      editor = atom.workspace.getActiveTextEditor()
      if lastEditor and lastEditor isnt newEditor and lastEditor isnt editor
        try
          lastEditor.destroy()
        catch
          console.error "LastEditor.destroy issue in changedFile"
      lastEditor = newEditor
      previousActivePane.activate()
