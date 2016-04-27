{CompositeDisposable} = require 'atom'
{File} = require 'atom'
fs = require 'fs-plus'

self = null

module.exports = Cparts =
  panes: null
  counterpart: null
  absMain: null
  main: null
  lastEditor: null
  editor: null
  previousActivePane: null
  toggleState: false
  observePane: null
  subscriptions: null
  destroyedPane: null
  g_headerRegEx: null
  g_sourceRegEx: null

  config:
    headerRegex:
      type: 'string'
      default: "\.(h|hh|HH|hpp|HPP)$"
      description: "regex for header extensions, suggested form \.(ext1|ext2|ext3)$"
    headerFlags:
      type: 'string'
      default: "gim"
      description: "flags used with the header regex"
    sourceRegex:
      type: 'string'
      default: "\.(c|cc|cC|cpp|CPP)$"
      description: "regex for source extensions, suggested form \.(ext1|ext2|ext3)"
    sourceFlags:
      type: 'string'
      default: "gim"
      description: "flags used with the source regex"
    enableDestroyWhenNoCounterpart:
      type: 'boolean'
      default: false
      description: "Closes the right hand pane when no counterpart found"

  createRegex: () ->
    hRegex = atom.config.get('cparts.headerRegex')
    sRegex = atom.config.get('cparts.sourceRegex')
    fhRegex = atom.config.get('cparts.headerFlags')
    fsRegex = atom.config.get('cparts.sourceFlags')
    @g_headerRegEx = new RegExp(hRegex,fhRegex)
    @g_sourceRegEx = new RegExp(sRegex,fsRegex)
    console.log "Regex"

  closeness: (string1,string2) ->
    arr = string1.split('/')
    arr2 = string2.split('/')
    len = Math.min(arr.length,arr2.length)
    equality = 0
    for index in [0..len]
      if arr[index] is arr2[index]
        equality++

    return equality

#-------------------------------------------------------------------

  activate: (state) ->
    @activateCommands()
    self = this
    @createRegex()

#-------------------------------------------------------------------

  activateCommands: () ->
    @subscriptions = CompositeDisposable
    console.debug "Activating commands "
    @subscriptions = atom.commands.add 'atom-workspace', 'cparts:toggle': => @toggle()
    @subscription = atom.config.onDidChange => @createRegex()

#-------------------------------------------------------------------

  activatePane: () ->
    console.debug "Activating Pane"
    return unless @panes = atom.workspace.getActivePane()
    @destroyedPane = @panes.onDidDestroy => @paneDestroyed()
    @observePane = @panes.observeActiveItem => @changedFile()
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
  destroyPane: () ->
    if self.lastEditor
      try
        self.lastEditor.save()
        self.lastEditor.destroy()
      catch
        console.debug "self.lastEditor.destroy issue in changedFile"
    self.lastEditor = null
#-------------------------------------------------------------------

  deactivate: () ->
    #Make sure any pane exists.
    return unless pane = atom.workspace.getPanes()
    @destroyPane()

#-------------------------------------------------------------------

  paneDestroyed: () ->
    console.debug "paneDestroyed"
    self.lastEditor = null
    @deactivatePane()
    @activatePane()

#-------------------------------------------------------------------

  toggle: () ->

    if @toggleState
      @toggleState = false;
      @deactivatePane()
      @deactivate()
      console.debug "toggle false"
    else
      @toggleState = true;
      return unless @panes = atom.workspace.getActivePane()
      @activatePane()
      console.debug "toggle true"

#-------------------------------------------------------------------

  closeness: (string1,string2) ->
    if string1 is null
      string1 = ""
    if string2 is null
      string2 = ""

    arr = string1.split('/')
    arr2 = string2.split('/')
    len = Math.min(arr.length,arr2.length)
    equality = 0
    for index in [0..len]
      if arr[index] is arr2[index]
        equality++

    return equality

#-------------------------------------------------------------------

  searchHeader: (absPath) ->

     fileName = absPath.match /[^\\/]+$/
     noExt = fileName[0].replace /\.[^/.]+$/ , ""

     if self.main is noExt
       if absPath.match(self.g_headerRegEx)
         if (self.closeness(absPath,self.absMain) >= self.closeness(self.counterpart,self.absMain))
           self.counterpart = absPath
     return true

#-------------------------------------------------------------------

  searchSource: (absPath) ->

    fileName = absPath.match /[^\\/]+$/
    noExt = fileName[0].replace /\.[^/.]+$/ , ""
    if self.main is noExt
      if absPath.match(self.g_sourceRegEx)
        if (self.closeness(absPath,self.absMain) >= self.closeness(self.counterpart,self.absMain))
          self.counterpart = absPath
    return true

#-------------------------------------------------------------------

  changedFile: () ->

    if not @toggleState
      return
    #get @editor and save previous active pane
    try
      return unless @editor = @panes.getActiveItem()
      @editor.getPath() #call a @editor member function to be certain (should be a typeof comparison)
    catch
      return

    return unless @previousActivePane = atom.workspace.getActivePane()

    return unless filePath = @editor.getPath()
    @counterpart = null

    return unless extension = filePath.match /\.[^/.]+$/
    if extension[0].match @g_sourceRegEx
      console.debug "source detected"
      @absMain = @editor.getPath()
      @main = @editor.getTitle().replace /\.[^/.]+$/ , ""
      console.debug @main
      for path in atom.project.getPaths()
        fs.traverseTree(path,@searchHeader,@searchHeader,@openFile)

      #try and find file with header extensions.
    else if extension[0].match @g_headerRegEx
      console.debug "header detected"
      @absMain = @editor.getPath()
      @main = @editor.getTitle().replace /\.[^/.]+$/ , ""
      for path in atom.project.getPaths()
        fs.traverseTree(path,@searchSource,@searchSource,@openFile)

      #try and find file with source extensions.
    else
      return

  openFile: () ->

    enableDestroyWhenNoCounterpart = atom.config.get('cparts.enableDestroyWhenNoCounterpart')
    #Create @editor uri
    uri = "cparts://editor/#{self.editor.id}"

    #Ensure existence of file.
    file = new File(self.counterpart,false)
    if not file.existsSync()
      if enableDestroyWhenNoCounterpart
        self.destroyPane()
      return

    fileOptions =
      searchAllPanes: false
      split:'right'

    #Recieve texteditor promise and destroy self.lastEditor
    atom.workspace.open(self.counterpart, fileOptions).done (newEditor) ->
      self.editor = atom.workspace.getActiveTextEditor()
      if self.lastEditor and self.lastEditor isnt newEditor and self.lastEditor isnt self.editor
        try
          self.lastEditor.save()
          self.lastEditor.destroy()
        catch
          console.error "self.lastEditor.destroy issue in changedFile"
      self.lastEditor = newEditor
      self.previousActivePane.activate()
