require("@PKGNAME@.logging")

MAR = MAR or {}
MAR.watches = MAR.watches or {}
MAR.reloading = MAR.reloading or false
MAR.logLevel = MAR.logLevel or logging.INFO

local marLead = "<112,229,0>(<73,149,0>MAR<112,229,0>): <255,255,255>"
local debugLead = "<255,165,0>(<200,120,0>debug<255,165,0>): <255,255,255>"
local errorLead = "<255,0,0>(<178,34,34>error<255,0,0>): <255,255,255>"

local appender = function(self, level, message)
  moveCursorEnd("main")
  local currentLine = getCurrentLine()
  if currentLine ~= "" then echo("\n") end
  decho(marLead)
  if level == logging.DEBUG then decho(debugLead) end
  if level == logging.ERROR then decho(errorLead) end
  cecho(f('{message}\n'))
end

local logger = logging.new(appender)
logger:setLevel(MAR.logLevel)

function MAR.toggleDebug()
  if MAR.logLevel == logging.DEBUG then
    logger:info('debug off')
    MAR.logLevel = logging.INFO
  else
    logger:info('debug on')
    MAR.logLevel = logging.DEBUG
  end
  logger:setLevel(MAR.logLevel)
end

local function waitForFile(path, timeout, callback, timeoutCallback)
  logger:debug(f('waitFile {timeout}'))
  local file = lfs.attributes(path)
  if file then
    callback()
  else
    if timeout == 0 then
      timeoutCallback()
    else
      tempTimer(1,
        function()
          waitForFile(path, timeout - 1, callback, timeoutCallback)
        end
      )
    end
  end
end

function MAR.watchModule(module, force)
  local path = getModulePath(module)
  if not table.contains(MAR.watches, path) or force then
    logger:info(f('adding file watch for {module} at {path}'))
    addFileWatch(path);
    MAR.watches[path] = module;
    MAR.watches[module] = path;
  end
end

function MAR.unwatchModule(module)
  local path = MAR.watches[module]
  if path then
    logger:info(f('removing file watch for {module} at {path}'))
    removeFileWatch(path);
    MAR.watches[path] = nil;
    MAR.watches[module] = nil;
  end
end

function MAR.initialize()
  local modules = getModules();
  for index, value in ipairs(modules) do
    MAR.watchModule(value)
    logger:debug(f('initial watch {value}'))
  end
  MAR.reloading = nil
end

function MAR.handlePathChange(_, path)
  logger:debug(f('path change: {path}'))
  local module = MAR.watches[path];
  if module then
    if module == "mudletMAR" then MAR.reloading = true end
    -- muddler cleans the build directory, so the module file gets deleted before being replaced
    -- so we need to wait for the file to exist if it doesn't yet
    local file = lfs.attributes(path);
    if file then
      logger:info(f('reloading {module}'))
      reloadModule(module);
    else
      waitForFile(path, 10,
        function()
          logger:info(f('reloading '..module))
          reloadModule(module);
          MAR.watchModule(module, true);
        end,
        function()
          logger:error(f('path {path} deleted'));
        end
      )
    end
  end
end

function MAR.handleInstall(_, module)
  logger:debug(f('install {module}'))
  MAR.watchModule(module)
end

function MAR.handleUninstall(_, module)
  logger:debug(f('uninstall {module}'))
  MAR.unwatchModule(module)

  if module == "mudletMAR" and not MAR.reloading then
    -- clean up registered events
    for _,id in ipairs(MAR.registeredEvents) do
      killAnonymousEventHandler(id)
    end
    -- clean up module watches
    local modules = getModules();
    for index, value in ipairs(modules) do
      MAR.unwatchModule(value)
    end
  end
end

MAR.registeredEvents = {
  registerAnonymousEventHandler("sysPathChanged", "MAR.handlePathChange"),
  registerAnonymousEventHandler("sysInstallModule", "MAR.handleInstall"),
  registerAnonymousEventHandler("sysLuaInstallModule","MAR.handleInstall"),
  registerAnonymousEventHandler("sysUninstallModule", "MAR.handleUninstall"),
  registerAnonymousEventHandler("sysLuaUninstallModule", "MAR.handleUninstall")
}

MAR.initialize()