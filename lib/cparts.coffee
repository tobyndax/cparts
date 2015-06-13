CpartsView = require './cparts-view'
{CompositeDisposable} = require 'atom'
toggleState = false


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

    #destroy the counterpart view
    return unless pane = atom.workspace.getPanes()

    if pane.length isnt 1
      otherPanes = pane[1..]
      for pane in otherPanes
        pane.destroy()

    #get editor
    return unless editor = atom.workspace.getActiveTextEditor()

    console.log editor.getPath()
    console.log 'Changed active item'
    return unless pane = atom.workspace.getPanes()
    if pane.length is 1
      atom.workspace.open(editor.getPath(),activatePane:false,split:'right')
