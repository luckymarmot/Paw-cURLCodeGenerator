{print} = require 'sys'
{spawn, exec} = require 'child_process'

file = 'cURLCodeGenerator.coffee'
identifier = 'com.luckymarmot.PawExtensions.cURLCodeGenerator'
target = '~/Library/Containers/com.luckymarmot.Paw/Data/Library/Application\\ Support/com.luckymarmot.Paw/Extensions/'

task 'build', ->
    coffee = spawn 'coffee', ['-c', file]
    coffee.stderr.on 'data', (data) ->
        process.stderr.write data.toString()
    coffee.stdout.on 'data', (data) ->
        print data.toString()
    coffee.on 'exit', (code) ->
        if code is 0
            console.log '>>> Build successful'
        else
            console.log '!!! Build failed'

task 'watch', ->
    spawn 'coffee', ['--watch', '--compile', file]

task 'install', ->
  console.log "Installing Extension to #{target}"
  exec([
    "mkdir -p #{target}#{identifier}"
    "cp -Rf * #{target}#{identifier}"
  ].join(' && '), (err, stdout, stderr) ->
    if err then console.log stderr.trim() else console.log 'Done'
    )