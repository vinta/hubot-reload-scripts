# Description:
#   Allows Hubot to (re)load scripts without restart
#
# Commands:
#   hubot reload - Reloads scripts without restart. Loads new scripts too. (a fork version that works perfectly)
#
# Author:
#   spajus
#   vinta
#   m-seldin

Fs       = require 'fs'
Path     = require 'path'

oldCommands = null
oldListeners = null

module.exports = (robot) ->

  robot.respond /reload/i, id:'reload-scripts.reload',  (msg) ->
    try
      oldCommands = robot.commands
      oldListeners = robot.listeners

      robot.commands = []
      robot.listeners = []

      reloadAllScripts msg, success, (err) ->
        msg.send err
    catch error
      console.log "Hubot reloader:", error
      msg.send "Could not reload all scripts: #{error}"

  success = (msg) ->
    # Cleanup old listeners and help
    for listener in oldListeners
      listener = {}
    oldListeners = null
    oldCommands = null
    msg.send "Reloaded all scripts"


  walkSync = (dir, filelist) ->
    #walk through given directory and collect files
    files = Fs.readdirSync(dir)
    filelist = filelist || []
    for file in files
      fullPath = Path.join(dir,file)
      robot.logger.debug "Scanning file : #{fullPath}"

      if (Fs.statSync(fullPath).isDirectory())
        filelist = walkSync(fullPath, filelist)
      else
        #add full path file to returning collection
        filelist.push(fullPath)
    return filelist

  # ref: https://github.com/srobroek/hubot/blob/e543dff46fba9e435a352e6debe5cf210e40f860/src/robot.coffee
  deleteScriptCache = (scriptsBaseDir) ->
    if Fs.existsSync(scriptsBaseDir)
      fileList = walkSync scriptsBaseDir

      for file in fileList.sort()
        robot.logger.debug "file: #{file}"
        if require.cache[require.resolve(file)]
          try
            cacheobj = require.resolve(file)
            console.log "Invalidate require cache for #{cacheobj}"
            delete require.cache[cacheobj]
          catch error
            console.log "Unable to invalidate #{cacheobj}: #{error.stack}"
    robot.logger.debug "Finished deleting script cache!"

  reloadAllScripts = (msg, success, error) ->
    robot = msg.robot
    robot.emit('reload_scripts')

    robot.logger.debug "Deleting script cache..."

    scriptsPath = Path.resolve ".", "scripts"
    deleteScriptCache scriptsPath
    robot.load scriptsPath

    scriptsPath = Path.resolve ".", "src", "scripts"
    deleteScriptCache scriptsPath
    robot.load scriptsPath

    robot.logger.debug "Loading hubot scripts..."

    hubotScripts = Path.resolve ".", "hubot-scripts.json"
    Fs.exists hubotScripts, (exists) ->
      if exists
        Fs.readFile hubotScripts, (err, data) ->
          if data.length > 0
            try
              scripts = JSON.parse data
              scriptsPath = Path.resolve "node_modules", "hubot-scripts", "src", "scripts"
              robot.loadHubotScripts scriptsPath, scripts
            catch err
              error "Error parsing JSON data from hubot-scripts.json: #{err}"
              return

    robot.logger.debug "Loading hubot external scripts..."

    robot.logger.debug "Deleting cache for apppulsemobile"
    deleteScriptCache Path.resolve ".","node_modules","hubot-apppulsemobile","src"

    externalScripts = Path.resolve ".", "external-scripts.json"
    Fs.exists externalScripts, (exists) ->
      if exists
        Fs.readFile externalScripts, (err, data) ->
          if data.length > 0
            try
              robot.logger.debug "DATA : #{data}"
              scripts = JSON.parse data

              if scripts instanceof Array
                for pkg in scripts
                  scriptPath = Path.resolve ".","node_modules",pkg,"src"
                  robot.logger.debug "Deleting cache for #{pkg}"
                  robot.logger.debug "Path : #{scripts}"
                  deleteScriptCache scriptPath
            catch err
              error "Error parsing JSON data from external-scripts.json: #{err}"
            robot.loadExternalScripts scripts
            return
    robot.logger.debug "step 5"

    success(msg)
