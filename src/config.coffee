"use strict"

path = require "path"

exports.defaults = ->
  bower:
    bowerDir:
      path: ".mimosa/bower_components"
      clean: false
    copy:
      enabled: true
      strategy: "packageRoot"
      exclude: []
      mainOverrides: {}
      pathMod: ["js", "javascript", "javascripts", "css", "stylesheet", "stylesheets", "vendor", "lib"]

exports.placeholder = ->
  """
  \t

    # bower:                  # Configuration for bower module
      # bowerDir:
        # path: ".mimosa/bower_components"  # The location mimosa-bower places temporary bower
                                            # assets.
        # clean: false              # whether or not to remove temporary bower assets after install
                                    # If enabled, mimosa-bower will not auto-install bower
                                    # dependencies when mimosa starts as that would cause mimosa to
                                    # install everything every time. If clean is enabled, the
                                    # "bower" command must be used to install dependencies.

      # copy:                       # configuration for the copying of assets from bower temp
                                    # directories into the project
        # enabled: true             # whether or not to copy the assets out of the bowerDir.path
                                    # into the project vendor location
        # exclude:[]                # An array of string paths or regexes. Files to exclude from
                                    # copying. Paths should be relative to the bowerdir.path or
                                    # absolute.
        # mainOverrides: {}         # Occasionally bower packages do not clearly indicate what file
                                    # is the main library file. In those cases, mimosa cannot find
                                    # the main files in order to copy them to the vendor directory.
                                    # json2 is a good example. This setting allows for setting
                                    # which files should be copied for a package. The key for this
                                    # object is the name of the package. The value is an array of
                                    # path strings representing the package's main files. The paths
                                    # should be relative to the root of the package. For example:
                                    # {"json2":["json2.js","json_parse.js"]}
        # strategy: "packageRoot"   # The copying strategy. "vendorRoot" places all files at the
                                    # root of the vendor directory. "packageRoot" places the files
                                    # in the vendor directory in a folder named for that package.
                                    # "none" will copy the assets into the vendor directory without
                                    # modification.
        # pathMod: ["js", "javascript", "javascripts", "css", "stylesheet", "stylesheets", "vendor", "lib"]
                                    # pathMod can be an array of strings or a regex. It is used to
                                    # strip full pieces of a path from the output file when the
                                    # selected strategy is "none". If a bower package script is in
                                    # "packageName/lib/js/foo.js" by default the output path would
                                    # have "lib" and "js" stripped. Feel free to suggest additions
                                    # to this based on your experience!

  """

exports.validate = (config, validators) ->
  errors = []

  if validators.ifExistsIsObject(errors, "bower config", config.bower)
    b = config.bower
    if validators.ifExistsIsObject(errors, "bower.bowerDir", b.bowerDir)
      if validators.ifExistsIsString(errors, "bower.bowerDir.path", b.bowerDir.path)
        b.bowerDir.pathFull = path.join config.root, b.bowerDir.path
      validators.ifExistsIsBoolean(errors, "bower.outputFolder.clean", b.bowerDir.clean)
    if validators.ifExistsIsObject(errors, "bower.copy", b.copy)
      validators.ifExistsIsBoolean(errors, "bower.copy.enabled", b.copy.enabled)
      if validators.ifExistsIsString(errors, "bower.copy.strategy", b.copy.strategy)
        if ["none", "vendorRoot", "packageRoot"].indexOf(b.copy.strategy) is -1
          errors.push 'Invalid bower.copy.strategy used. Must be "none", "vendorRoot" or "packageRoot".'

      validators.ifExistsFileExcludeWithRegexAndString(errors, "bower.copy.exclude", b.copy, b.bowerDir.pathFull)

      if validators.ifExistsIsObject(errors, "bower.copy.mainOverrides", b.copy.mainOverrides)
        o = b.copy.mainOverrides
        Object.keys(o).forEach (key) ->
          validators.isArrayOfStrings(errors, "bower.copy.mainOverrides values", o[key])

      if b.copy.pathMod?
        if Array.isArray b.copy.pathMod
          notString = false
          regexArray = []
          for item in b.copy.pathMod
            if typeof item is "string"
              regexArray.push "^#{item}$"
            else
              notString = true
              break

          if notString
            errors.push "bower.copy.pathMod must be a regex or an array of strings."
          else
            regexString = "(" + regexArray.join("|") + ")"
            b.copy.pathMod = new RegExp(regexString)

        else
          unless b.copy.pathMod instanceof RegExp
            errors.push "bower.copy.pathMod must be a regex or an array of strings."

  errors