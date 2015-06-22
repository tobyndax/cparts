CpartsView = require './cparts-view'
{CompositeDisposable} = require 'atom'
toggleState = false
lastEditor = null
panes = null
subscriptions = null

module.exports = Cparts =
  cpartsView: null
  subscriptions: null

  activate: (state) ->

    #Add subscriptions
    @subscriptions = new CompositeDisposable
    # Register command that toggles this view
    @activateCommands()

  activateCommands: () ->
    @subscriptions.add atom.commands.add 'atom-workspace', 'cparts:test': => @toggle()

  activatePane: () ->
    return unless panes = atom.workspace.getActivePane()
    console.log panes
    @subscriptions.add panes.observeActiveItem => @changedFile()
    @subscriptions.add panes.onDidDestroy => @paneDestroyed()

  deactivatePane: () ->
    @subscriptions.dispose()
    @activateCommands()

  deactivate: () ->
    return unless pane = atom.workspace.getPanes()
    if lastEditor
      lastEditor.destroy()
    lastEditor = null
    panes = null

  paneDestroyed: () ->
    @deactivatePane()
    @activatePane()


  toggle: () ->

    if toggleState
      @deactivatePane()
      @deactivate()
      toggleState = false;
    else
      @activatePane(null)
      toggleState = true;
      @changedFile()

    console.log "State: "
    console.log toggleState

  changedFile: () ->
    if not toggleState
      return

    #get editor and save previous active pane
    return unless editor = panes.getActiveItem()
    previousActivePane = atom.workspace.getActivePane()

    #Create editor uri
    uri = "cparts://editor/#{editor.id}"
    console.log uri

    #setup options for fileopening
    options =
      searchAllPanes: false
      split:'right'
    filePath = editor.getPath()
    console.log filePath

    #Recieve texteditor promise and destroy lastEditor
    atom.workspace.open(filePath, options).done (newEditor) ->
      if lastEditor and lastEditor isnt newEditor
        lastEditor.destroy()
      lastEditor = newEditor
      #activate whichever pane was active before.
      previousActivePane.activate()
      return
