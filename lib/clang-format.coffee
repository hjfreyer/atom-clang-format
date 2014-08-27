exec = require('child_process').exec
util = require('util')

class ClangFormatRun
  constructor: (editor) ->
    @editor = editor
    @exe = atom.config.get('clang-format.executable')
    @style = atom.config.get('clang-format.style')
    @cursor = @editor.getCursorBufferPosition()
    @screenCursor = @editor.getCursorScreenPosition()

  format: ->
    @execFormat([])

  formatSelection: ->
    selection = @editor.getSelectedBufferRange()
    @execFormat([util.format('-lines=%d:%d',
      selection.start.row + 1, selection.end.row + 1,
    )])

  execFormat: (extra_argv) ->
    cmdList = [@exe]
    cursorInt = @editor.getTextInBufferRange([[0, 0], @cursor]).length
    cmdList.push('--cursor=' + cursorInt)
    cmdList.push('-style=' + @style)
    cmdList = cmdList.concat(extra_argv)
    cmdList.push('"' + @editor.getPath() + '"')
    exec cmdList.join(' '), (err, stdout, stderr) =>
      if err
        console.log(err)
        console.log(stdout)
        console.log(stderr)
      else
        @editor.setText(stdout)
        @editor.setCursorScreenPosition(@screenCursor)

module.exports =
class ClangFormat
  constructor: (state) ->
    atom.workspace.eachEditor (editor) =>
      @handleBufferEvents(editor)

    atom.workspaceView.command 'clang-format:format', @format

    atom.workspaceView.command 'clang-format:format-selection',
      @formatSelection

  format: ->
    editor = atom.workspace.getActiveEditor()
    if editor
      new ClangFormatRun(editor).format()

  formatSelection: ->
    editor = atom.workspace.getActiveEditor()
    if editor
      new ClangFormatRun(editor).formatSelection()

  destroy: ->
    atom.unsubscribe(atom.project)

  handleBufferEvents: (editor) ->
    buffer = editor.getBuffer()
    atom.subscribe buffer, 'saved', =>
      scope = editor.getCursorScopes()[0]
      if atom.config.get('clang-format.formatOnSave') and scope is 'source.c++'
        @format(editor)

    atom.subscribe buffer, 'destroyed', ->
      atom.unsubscribe(editor.getBuffer())
  #
  # format: (editor) ->
  #   if editor and editor.getPath()
  #     exe = atom.config.get('clang-format.executable')
  #     style = atom.config.get('clang-format.style')
  #     path = editor.getPath()
  #     cursor = @getCurrentCursorPosition(editor)
  #     exec exe + ' -cursor=' + cursor.toString() + ' -style ' + style + ' "' + path + '"', (err, stdout, stderr) =>
  #       if err
  #         console.log(err)
  #         console.log(stdout)
  #         console.log(stderr)
  #       else
  #
  # formatSelection: (editor) ->
  #   if editor and editor.getPath()
  #     exe = atom.config.get('clang-format.executable')
  #     style = atom.config.get('clang-format.style')
  #     path = editor.getPath()
  #     cursor = @getCurrentCursorPosition(editor)
  #     selection = editor.getSelectedBufferRange()
  #
  #     cmd = util.format('%s -cursor=%s -style=%s -lines=%d:%d "%s"',
  #                       exe, cursor.toString(), style,
  #                       selection.start.row + 1, selection.end.row + 1,
  #                       path)
  #
  #
  #
  #     exec cmd, (err, stdout, stderr) =>
  #       if err
  #         console.log(err)
  #         console.log(stdout)
  #         console.log(stderr)
  #       else
  #         editor.setText(@getReturnedFormattedText(stdout))
  #         returnedCursorPos = @getReturnedCursorPosition(stdout)
  #         convertedCursorPos = @convertReturnedCursorPosition(editor, returnedCursorPos)
  #
  # getEndJSONPosition: (text) ->
  #   for i in [0..(text.length-1)]
  #     if text[i] is '\n' or text[i] is '\r'
  #       return i+1
  #   return -1
  #
  # getReturnedCursorPosition: (stdout) ->
  #   parsed = JSON.parse stdout.slice(0, @getEndJSONPosition(stdout))
  #   return parsed.Cursor
  #
  # getReturnedFormattedText: (stdout) ->
  #   return stdout.slice(@getEndJSONPosition(stdout))
  #
  # getCurrentCursorPosition: (editor) ->
  #   cursorPosition =
  #   text = editor.getTextInBufferRange([[0, 0], cursorPosition])
  #   return text.length
  #
  # convertReturnedCursorPosition: (editor, position) ->
  #   text = editor.getText()
  #   x = y = 0
  #
  #   for i in [0..(text.length-1)]
  #     if position is 0
  #       return [y, x]
  #     else if text[i] is '\n' or text[i] is '\r' or text[i] is '\f'
  #       x = 0
  #       y++
  #     else
  #       x++
  #     position--
  #
  #   return [y, x]

