CpartsView = require './cparts-view'
{CompositeDisposable} = require 'atom'
toggleState = false
lastEditor = null
num = 0

module.exports = Cparts =
  cpartsView: null
  subscriptions: null

  activate: (state) ->

    #Add subscriptions
    @subscriptions = new CompositeDisposable
    return unless panes = atom.workspace.getActivePane()
    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'cparts:test': => @toggle()
    @subscriptions.add panes.observeActiveItem => @changedFile()


  deactivate: ->
    @subscriptions.dispose()
    lastEditor = null
    return unless pane = atom.workspace.getPanes()
    if pane.length is 1
      #
    else
      secondPane = pane[1]
      secondPane.destroy()

  toggle: () ->

    toggleState = not toggleState

    if not toggleState
      return unless pane = atom.workspace.getPanes()
      if pane.length isnt 1
        secondPane = pane[1]
        secondPane.destroy()
    else
      @changedFile()

  changedFile: () ->
    if not toggleState
      return

    #get editor
    return unless editor = atom.workspace.getActiveTextEditor()
    ###
    if editor is lastEditor
      console.log "lastEditor is now active editor"
      console.log atom.workspace.getActiveTextEditor().getPath()
    ###
    #Create editor uri
    uri = "cparts://editor/#{editor.id}"
    console.log uri

    previousActivePane = atom.workspace.getActivePane()

    options =
      searchAllPanes: false
      split:'right'
    filePath = atom.workspace.getActiveTextEditor().getPath()
    console.log filePath
    #Recieve texteditor promise and destroy lastEditor
    atom.workspace.open(filePath, options).done (newEditor) ->
      if lastEditor and lastEditor isnt newEditor
        lastEditor.destroy()
      lastEditor = newEditor
      #activate whichever pane was active before.
      previousActivePane.activate()
      return
