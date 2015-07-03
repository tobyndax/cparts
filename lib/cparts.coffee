
{CompositeDisposable} = require 'atom'
{File} = require 'atom'
fs = require 'fs-plus'
toggleState = false
lastEditor = null
panes = null
subscriptions = null
main = null
counterpart = null


module.exports = Cparts =
  cpartsView: null
  subscriptions: null
#-------------------------------------------------------------------

  activate: (state) ->
    #Create subscription
    @subscriptions = new CompositeDisposable
    #Activate command that toggles this view
    @activateCommands()

#-------------------------------------------------------------------

  activateCommands: () ->
    @subscriptions.add atom.commands.add 'atom-workspace', 'cparts:toggle': => @toggle()

#-------------------------------------------------------------------

  activatePane: () ->
    #get new current pane to track
    return unless panes = atom.workspace.getActivePane()
    #activate subscriptions
    @subscriptions.add panes.observeActiveItem => @changedFile()
    @subscriptions.add panes.onDidDestroy => @paneDestroyed()

#-------------------------------------------------------------------

  deactivatePane: () ->
    #Stop tracking panes by removing subscriptions, readd keycommands
    @subscriptions.dispose()
    @activateCommands()

#-------------------------------------------------------------------

  deactivate: () ->
    #Make sure any pane exists.
    return unless pane = atom.workspace.getPanes()
    if lastEditor
      try
        lastEditor.destroy()
      catch
        console.log "LastEditor.destroy issue in changedFile"
    lastEditor = null
    panes = null

#-------------------------------------------------------------------

  paneDestroyed: () ->
    @deactivatePane()
    @activatePane()

#-------------------------------------------------------------------

  toggle: () ->

    if toggleState
      @deactivatePane()
      @deactivate()
      toggleState = false;
    else
      @activatePane(null)
      toggleState = true;
      @changedFile()

#-------------------------------------------------------------------

   searchHeader: (absPath) ->
     fileName = absPath.match /[^\\/]+$/
     noExt = fileName[0].replace /\.[^/.]+$/ , ""
     if main is noExt
       #console.log absPath
       if absPath.match /\.(h|hh|HH|hpp|HPP)$/gim
         counterpart = absPath
         return true
     return true

#-------------------------------------------------------------------

    searchSource: (absPath) ->
      fileName = absPath.match /[^\\/]+$/
      noExt = fileName[0].replace /\.[^/.]+$/ , ""
      if main is noExt
        #console.log absPath
        if absPath.match /\.(c|cc|cC|cpp|CPP)$/gim
          counterpart = absPath
          return true
      return true

#-------------------------------------------------------------------

  changedFile: () ->
    if not toggleState
      return

    #get editor and save previous active pane
    return unless editor = panes.getActiveItem()
    #make sure it is actually a editor, not something else.
    try
      editor.getPath()
    catch
      return

    previousActivePane = atom.workspace.getActivePane()

    return unless filePath = editor.getPath()

    return unless extension = filePath.match /\.[^/.]+$/
    if extension[0].match /\.(c|cc|cC|cpp|CPP)$/gim
      console.log "source detected"
      main = editor.getTitle().replace /\.[^/.]+$/ , ""
      for path in atom.project.getPaths()
        fs.traverseTreeSync(path,@searchHeader)
      #try and find file with header extensions.
    else if extension[0].match /\.(h|hh|HH|hpp|HPP)$/gim
      console.log "header detected"
      main = editor.getTitle().replace /\.[^/.]+$/ , ""
      for path in atom.project.getPaths()
        fs.traverseTreeSync(path,@searchSource)
      #try and find file with source extensions.
    else
      return

    #Create editor uri
    uri = "cparts://editor/#{editor.id}"
    #console.log uri

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
          console.log "LastEditor.destroy issue in changedFile"
      lastEditor = newEditor
      previousActivePane.activate()
      return
