"use strict";
var bower, cleanTempDir, fs, logger, path, utils, wrench, _, _cleanEmptyDirs, _cleanInstalledLibs, _removeDirs;

fs = require('fs');

path = require('path');

_ = require('lodash');

bower = require("bower-canary");

wrench = require("wrench");

logger = require("logmimosa");

utils = require('./utils');

_cleanInstalledLibs = function(copyConfigs) {
  var copyConfig, err, _i, _len, _results;
  _results = [];
  for (_i = 0, _len = copyConfigs.length; _i < _len; _i++) {
    copyConfig = copyConfigs[_i];
    try {
      fs.unlinkSync(copyConfig.out);
      _results.push(logger.info("Removed file [[ " + copyConfig.out + " ]]"));
    } catch (_error) {
      err = _error;
      _results.push(logger.warn("Unable to clean file [[ " + copyConfig.out + " ]], was it moved from this location?"));
    }
  }
  return _results;
};

_removeDirs = function(dirs) {
  var dir, err, _i, _len, _results;
  _results = [];
  for (_i = 0, _len = dirs.length; _i < _len; _i++) {
    dir = dirs[_i];
    try {
      fs.rmdirSync(dir);
      _results.push(logger.info("Cleaned up empty bower package directory [[ " + dir + " ]]"));
    } catch (_error) {
      err = _error;
      if (err.code !== 'ENOTEMPTY') {
        _results.push(logger.error("Unable to delete directory, [[ " + dirPath + " ]] :", err));
      } else {
        _results.push(void 0);
      }
    }
  }
  return _results;
};

exports.cleanTempDir = cleanTempDir = function(mimosaConfig, force) {
  if ((force || mimosaConfig.bower.bowerDir.clean) && fs.existsSync(mimosaConfig.bower.bowerDir.pathFull)) {
    wrench.rmdirSyncRecursive(mimosaConfig.bower.bowerDir.pathFull);
    return logger.info("Cleaned temp bower output directory [[ " + mimosaConfig.bower.bowerDir.pathFull + " ]]");
  }
};

_cleanEmptyDirs = function(mimosaConfig, packages) {
  var allDirs, cssDirs, jsDirs;
  jsDirs = wrench.readdirSyncRecursive(mimosaConfig.vendor.javascripts).map(function(dir) {
    return path.join(mimosaConfig.vendor.javascripts, dir);
  });
  cssDirs = wrench.readdirSyncRecursive(mimosaConfig.vendor.stylesheets).map(function(dir) {
    return path.join(mimosaConfig.vendor.stylesheets, dir);
  });
  allDirs = _.uniq(jsDirs.concat(cssDirs));
  allDirs = allDirs.filter(function(dir) {
    return _.intersection(dir.split(path.sep), packages).length > 0;
  });
  allDirs = _.sortBy(allDirs, function(dir) {
    return dir.length;
  }).reverse();
  return _removeDirs(allDirs);
};

exports.bowerClean = function(mimosaConfig) {
  bower.config.directory = mimosaConfig.bower.bowerDir.path;
  return bower.commands.list({
    paths: true
  }).on('end', function(paths) {
    var packages;
    packages = Object.keys(paths);
    return utils.gatherPathConfigs(mimosaConfig, packages, function(copyConfigs) {
      _cleanInstalledLibs(copyConfigs);
      cleanTempDir(mimosaConfig, true);
      if (mimosaConfig.bower.copy.strategy !== "vendorRoot") {
        _cleanEmptyDirs(mimosaConfig, packages);
      }
      return logger.success("Bower artifacts cleaned up.");
    });
  });
};