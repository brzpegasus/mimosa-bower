"use strict"

path = require "path"

exports.defaults = ->
  bower:
    bowerDir:
      path: ".mimosa/bower_components"
      clean: false
    copy:
      enabled: true
      defaultStrategy: "packageRoot" # not exposed or documented
      strategy: "packageRoot"
      exclude: []
      overridesArrays: {}
      overridesObjects: {}
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
                                    # the main files to copy them to the vendor directory. json2 is
                                    # a good example. mainOverrides allows for setting which files
                                    # should be copied for a package. The key for this object is
                                    # the name of the package. The value is an array of path
                                    # strings representing the package's main files. The paths
                                    # should be relative to the root of the package. For example:
                                    # {"json2":["json2.js","json_parse.js"]}. The paths can also
                                    # be to directories. That will include all the directory's
                                    # files. mainOverrides packages can also be provided an object
                                    # in addition to string paths. The object maps input paths to
                                    # output paths and allow for specific placement of files and
                                    # folders. Ex {"json2":{"json2.js":"json-utils/json2.js"}. In
                                    # this case the "json2.js" file will be placed in
                                    # "json-utils/json2.js" in the vendor.javascripts folder.
        # strategy: "packageRoot"   # The copying strategy. "vendorRoot" places all files at the
                                    # root of the vendor directory. "packageRoot" places the files
                                    # in the vendor directory in a folder named for that package.
                                    # "none" will copy the assets into the vendor directory without
                                    # modification.  strategy can also be an object with keys that
                                    # match the names of packages and values of strategy types.
                                    # When using a strategy object, the key of "*" provides a
                                    # default strategy. If only 2 of 10 packages are specified
                                    # the rest get the "*" strategy. If no "*" is provided,
                                    # "packageRoot" is the assumed default.
        # pathMod: ["js", "javascript", "javascripts", "css", "stylesheet", "stylesheets", "vendor", "lib"]
                                    # pathMod can be an array of strings or a regex. It is used to
                                    # strip full pieces of a path from the output file when the
                                    # selected strategy is "none". If a bower package script is in
                                    # "packageName/lib/js/foo.js" by default the output path would
                                    # have "lib" and "js" stripped. Feel free to suggest additions
                                    # to this based on your experience!

  """

strategyVal = (errors, strat) ->
  if ["none", "vendorRoot", "packageRoot"].indexOf(strat) is -1
    errors.push 'Invalid bower.copy.strategy used. Must be "none", "vendorRoot" or "packageRoot".'
    false
  else
    true

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

      if typeof b.copy.strategy is "string"
        if strategyVal errors, b.copy.strategy
          b.copy.defaultStrategy = b.copy.strategy
          b.copy.strategy = {}
      else if typeof b.copy.strategy is "object" and not Array.isArray b.copy.strategy
        Object.keys(b.copy.strategy).forEach (key) ->
          unless typeof key is "string" and typeof b.copy.strategy[key] is "string"
            errors.push "bower.copy.strategy object must have a string key and a string value."
          else
            strategyVal errors, b.copy.strategy[key]

        if errors.length is 0
          if b.copy.strategy["*"]
            b.copy.defaultStrategy = b.copy.strategy["*"]
      else
        errors.push "bower.copy.strategy must be a string or an object"

      validators.ifExistsFileExcludeWithRegexAndString(errors, "bower.copy.exclude", b.copy, b.bowerDir.pathFull)

      if validators.ifExistsIsObject(errors, "bower.copy.mainOverrides", b.copy.mainOverrides)
        o = b.copy.mainOverrides
        Object.keys(o).forEach (pack) ->
          overrides = o[pack]
          if validators.isArray errors, "bower.copy.mainOverrides values", overrides
            overrides.forEach (override) ->
              if typeof override is "string"
                unless b.copy.overridesArrays[pack]
                  b.copy.overridesArrays[pack] = []
                b.copy.overridesArrays[pack].push override
              else if type of override is "object" and not Array.isArray override
                unless b.copy.overridesObjects[pack]
                  b.copy.overridesObjects[pack] = {}

                Object.keys(override).forEach (oKey) ->
                  if typeof oKey is "string" and typeof override[oKey] is "string"
                    b.copy.overridesObjects[pack] = _.extend(b.copy.overridesObjects[pack], override)
                  else
                    errors.push "Objects provided to bower.copy.mainOverrides package array must have keys and values of strings"
              else
                errors.push "Items provided as bower.copy.mainOverrides entries must be objects or strings"

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
