CpartsView = require './cparts-view'
{CompositeDisposable} = require 'atom'
toggleState = false
title = null
lastEditor = null
num = 0

module.exports = Cparts =
  cpartsView: null
  subscriptions: null

  activate: (state) ->
    #@cpartsView = new CpartsView(state.cpartsViewState)

      # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable
    return unless panes = atom.workspace.getActivePane()
    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'cparts:test': => @toggle()
    @subscriptions.add atom.commands.add 'atom-workspace', 'cparts:deactivate': => @deactivate()
    @subscriptions.add panes.observeActiveItem => @changedFile()


  deactivate: ->
    @subscriptions.dispose()
    title = null
    return unless pane = atom.workspace.getPanes()
    if pane.length is 1
      #
    else
      secondPane = pane[1]
      secondPane.destroy()

  toggle: () ->
    console.log 'Cparts is running!'
    toggleState = not toggleState
    console.log toggleState
    if not toggleState
      return unless pane = atom.workspace.getPanes()
      if pane.length is 1
        #
      else
        secondPane = pane[1]
        secondPane.destroy()
    else
      @changedFile()

  changedFile: () ->
    if not toggleState
      return

    #get editor
    return unless editor = atom.workspace.getActiveTextEditor()
    console.log editor.getPath()
    console.log 'Changed active item'

    uri = "cparts://editor/#{editor.id}"
    console.log uri
    tempTitle ="#{editor.id}"

    previousActivePane = atom.workspace.getActivePane()
    options =
      searchAllPanes: false
      split:'right'
    filePath = atom.workspace.getActiveTextEditor().getPath()
    atom.workspace.open(filePath, options).done (newEditor) ->
      console.log lastEditor
      if lastEditor
        lastEditor.destroy()
      lastEditor = newEditor
      return
