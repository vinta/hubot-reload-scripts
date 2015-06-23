# Description:
#   Allows Hubot to (re)load scripts without restart
#
# Commands:
#   hubot reload - Reloads scripts without restart. Loads new scripts too. (a fork version that works perfectly)
#
# Author:
#   spajus
#   vinta

Fs       = require 'fs'
Path     = require 'path'

oldCommands = null
oldListeners = null

module.exports = (robot) ->

  robot.respond /reload/i, (msg) ->
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

# ref: https://github.com/srobroek/hubot/blob/e543dff46fba9e435a352e6debe5cf210e40f860/src/robot.coffee
deleteScriptCache = (scriptsBaseDir) ->
  if Fs.existsSync(scriptsBaseDir)
    for file in Fs.readdirSync(scriptsBaseDir).sort()
      full = Path.join scriptsBaseDir, file
      if require.cache[require.resolve(full)]
        try
          cacheobj = require.resolve(full)
          console.log "Invalidate require cache for #{cacheobj}"
          delete require.cache[cacheobj]
        catch error
          console.log "Unable to invalidate #{cacheobj}: #{error.stack}"

reloadAllScripts = (msg, success, error) ->
  robot = msg.robot
  robot.emit('reload_scripts')

  scriptsPath = Path.resolve ".", "scripts"
  deleteScriptCache scriptsPath
  robot.load scriptsPath

  scriptsPath = Path.resolve ".", "src", "scripts"
  deleteScriptCache scriptsPath
  robot.load scriptsPath

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

  externalScripts = Path.resolve ".", "external-scripts.json"
  Fs.exists externalScripts, (exists) ->
    if exists
      Fs.readFile externalScripts, (err, data) ->
        if data.length > 0
          try
            scripts = JSON.parse data
          catch err
            error "Error parsing JSON data from external-scripts.json: #{err}"
          robot.loadExternalScripts scripts
          return

  success(msg)
