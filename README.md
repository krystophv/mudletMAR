# Module Autoreload for Mudlet

Module Autoreload does pretty much what it says on the tin - it will automatically reload installed Mudlet modules when they change on disk. This was developed in large part to support a workflow similar to [Hot Module Replacement](https://webpack.js.org/guides/hot-module-replacement/) for Webpack. By combining [muddler](https://github.com/demonnic/muddler) as a [Run on save](https://marketplace.visualstudio.com/items?itemName=emeraldwalk.RunOnSave) action in VSCode with this module you can accomplish a `Save->Build->Reload` workflow for `muddler` projects in Mudlet.  

Upon install, MAR will set up file watches for each of the installed modules and will trigger a reload. It will watch newly installed modules and unwatch uninstalled modules. `muddler` needs to clean its build directory before each build, so the module path file will be temporarily removed on rebuild and this will wait for the fresh build to arrive before reloading and applying the new build.

It comes with a single alias: `MAR debug` to toggle debug output.

Logging is provided via [lualogging](https://github.com/lunarmodules/lualogging)