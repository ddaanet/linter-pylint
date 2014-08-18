{exec, child} = require 'child_process'
linterPath = atom.packages.getLoadedPackage("linter").path
Linter = require "#{linterPath}/lib/linter"
{log, warn} = require "#{linterPath}/lib/utils"


class LinterPylint extends Linter
  @enabled = false # false until executable checked
  @syntax: 'source.python' # fits all *.py-files
  cmd: ['pylint'
        "--msg-template='{line},{column},{category},{msg_id}:{msg}'"
        '--reports=n']

  linterName: 'pylint'

  regex: '^(?<line>\\d+),(?<col>\\d+),\
          ((?<error>error)|(?<warning>warning)),\
          (?<msg_id>\\w\\d+):(?<message>.*)$'
  regexFlags: 'm'

  constructor: (@editor) ->
    super @editor  # sets @cwd to the dirname of the current file
    # if we're in a project, use that path instead
    @cwd = atom.project.path ? @cwd
    exec 'pylint --version', cwd: @cwd, @executionCheckHandler
    log 'Linter-Pylint: initialization completed'

  # Private: handles the initial 'version' call, extracts the version and
  # enables the linter
  executionCheckHandler: (error, stdout, stderr) =>
    versionRegEx = /pylint ([\d\.]+)\,/
    if not versionRegEx.test(stdout)
      result = if error? then '#' + error.code + ': ' else ''
      result += 'stdout: ' + stdout if stdout.length > 0
      result += 'stderr: ' + stderr if stderr.length > 0
      console.error "Linter-Pylint: 'pylint' was not executable: " + result
    else
      log "Linter-Pylint: found pylint " + versionRegEx.exec(stdout)[1]
      @enabled = true # everything is fine, the linter is ready to work

  lintFile: (filePath, callback) =>
    if @enabled
      cmdargs = @getCmdAndArgs(filePath)
      command = cmdargs.command + ' ' + cmdargs.args.join(' ')
      exec command, {cwd: @cwd}, (error, stdout, stderr) =>
        warn 'stderr', stderr
        log 'stdout', stdout
        @processMessage(stdout, callback)
    else
      @processMessage "", callback

  formatMessage: (match) ->
    "#{match.msg_id}: #{match.message}"

module.exports = LinterPylint
