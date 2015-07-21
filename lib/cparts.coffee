
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
  commands: null
  destroyedPane: null

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

#-------------------------------------------------------------------

  activateCommands: () ->
    @commands = CompositeDisposable
    console.debug "Activating commands "
    @commands = atom.commands.add 'atom-workspace', 'cparts:toggle': => @toggle()

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

  deactivate: () ->
    #Make sure any pane exists.
    return unless pane = atom.workspace.getPanes()
    if self.lastEditor
      try
        self.lastEditor.save()
        self.lastEditor.destroy()
      catch
        console.debug "self.lastEditor.destroy issue in changedFile"
    self.lastEditor = null

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
       if absPath.match /\.(h|hh|HH|hpp|HPP)$/gim
         if (self.closeness(absPath,self.absMain) > self.closeness(self.counterpart,self.absMain))
           self.counterpart = absPath
     return true

#-------------------------------------------------------------------

  searchSource: (absPath) ->

    fileName = absPath.match /[^\\/]+$/
    noExt = fileName[0].replace /\.[^/.]+$/ , ""
    if self.main is noExt
      if absPath.match /\.(c|cc|cC|cpp|CPP)$/gim
        if (self.closeness(absPath,self.absMain) > self.closeness(self.counterpart,self.absMain))
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
    if extension[0].match /\.(c|cc|cC|cpp|CPP)$/gim
      console.debug "source detected"
      @absMain = @editor.getPath()
      @main = @editor.getTitle().replace /\.[^/.]+$/ , ""
      for path in atom.project.getPaths()
        fs.traverseTree(path,@searchHeader,@searchHeader,@openFile)
      #try and find file with header extensions.
    else if extension[0].match /\.(h|hh|HH|hpp|HPP)$/gim
      console.debug "header detected"
      @absMain = @editor.getPath()
      @main = @editor.getTitle().replace /\.[^/.]+$/ , ""
      for path in atom.project.getPaths()
        fs.traverseTree(path,@searchSource,@searchSource,@openFile)
      #try and find file with source extensions.
    else
      return

  openFile: () ->
    #Create @editor uri
    uri = "cparts://editor/#{self.editor.id}"

    #Ensure existence of file.
    file = new File(self.counterpart,false)
    if not file.existsSync()
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
