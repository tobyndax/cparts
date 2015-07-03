
{CompositeDisposable} = require 'atom'
{File} = require 'atom'
fs = require 'fs-plus'
toggleState = false
lastEditor = null
panes = null
subscriptions = null
commands = null
main = null
counterpart = null


module.exports = Cparts =
  cpartsView: null
  subscriptions: null
#-------------------------------------------------------------------

  activate: (state) ->
    #Create subscription
    subscriptions = new CompositeDisposable
    commands = new CompositeDisposable
    #Activate command that toggles this view
    @activateCommands()

#-------------------------------------------------------------------

  activateCommands: () ->
    console.log "Activating commands "
    commands.add atom.commands.add 'atom-workspace', 'cparts:toggle': => @toggle()

#-------------------------------------------------------------------

  activatePane: () ->
    #get new current pane to track
    @deactivatePane()
    console.log "Activating Pane"
    return unless panes = atom.workspace.getActivePane()
    console.log  panes
    #activate subscriptions
    subscriptions.add panes.observeActiveItem => @test()
    #subscriptions.add panes.onDidDestroy => @paneDestroyed()

#-------------------------------------------------------------------

  deactivatePane: () ->
    #Stop tracking panes by removing subscriptions, readd keycommands
    console.log "Deactivating pane"
    subscriptions.clear()
    subscriptions.dispose()

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
    console.log "paneDestroyed"
    @deactivatePane()
    @activatePane()

#-------------------------------------------------------------------

  test: () ->
    console.log "test"

  toggle: () ->

    if toggleState
      toggleState = false;
      @deactivatePane()
      @deactivate()
      console.log "toggle false"
      console.log subscriptions
    else
      toggleState = true;
      return unless panes = atom.workspace.getActivePane()
      @test()
      @activatePane()
      console.log "toggle true"

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
