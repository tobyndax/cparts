
{CompositeDisposable} = require 'atom'
{File} = require 'atom'
fs = require 'fs-plus'
toggleState = false
lastEditor = null
panes = null
subscriptions = null

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
    #On deactivation destroy lastEditor
    #   subscriptions.dispose()
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

    #Create editor uri
    uri = "cparts://editor/#{editor.id}"
    console.log uri

    filePath = editor.getPath()
    extension = filePath.match /\.[^/.]+$/
    ###
    
    We can use atom.project.getPaths() to get each top path for all disjoint
    directories in the project. (Even when files haven't been opened as a project)
    Then using fs-plus traverseTree(sync) to apply our regexp to every file in
    the project, returning the file when a match is made. traverseTree calls a
    function (onFile) that takes one argument the absolute path to the file, so
    that should work fine, however I am not certain about returning values from it.
    However, since it's always a question of exactly one instance a localscope
    parameter could be set to circumvent the return issue (if there is one)

    We need to detect the triggering file endings, preferably with a regexp,
    and incorperate it into the config file so end-users can use it.
    Maybe we need two search functions one which finds source files, and one
    which finds header files. searchSource and searchHeader. Also regexps.

    We definitely need a function which builds regexps from the config file.

    ###


    #we need something to find different extensions here.
    if extension[0] isnt ".cc"
      return

    newFilePath = filePath.replace /\.[^/.]+$/ , ".h"

    file = new File(newFilePath,false)
    console.log file.existsSync()
    console.log atom.project

    if not file.existsSync()
      return

    fileOptions =
      searchAllPanes: false
      split:'right'

    #Recieve texteditor promise and destroy lastEditor
    atom.workspace.open(newFilePath, fileOptions).done (newEditor) ->
      editor = atom.workspace.getActiveTextEditor()
      if lastEditor and lastEditor isnt newEditor and lastEditor isnt editor
        try
          lastEditor.destroy()
        catch
          console.log "LastEditor.destroy issue in changedFile"
      lastEditor = newEditor
      previousActivePane.activate()
      return
