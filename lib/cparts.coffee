CpartsView = require './cparts-view'
{CompositeDisposable} = require 'atom'

module.exports = Cparts =
  cpartsView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @cpartsView = new CpartsView(state.cpartsViewState)

      # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable
    return unless panes = atom.workspace.getActivePane()
    console.log panes
    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'cparts:test': => @test()
    @subscriptions.add panes.observeActiveItem => @changedFile()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @cpartsView.destroy()

  serialize: ->
    cpartsViewState: @cpartsView.serialize()

  test: ->
    console.log 'Cparts is running!'

  changedFile: ->
    console.log 'Changed active item'
    return unless pane = atom.workspace.getPanes()
    if pane.length is 1
      secondPane = pane[0].splitRight()
    else
      secondPane = pane[1]
    secondPane.activate()

    console.log pane
    console.log secondPane
