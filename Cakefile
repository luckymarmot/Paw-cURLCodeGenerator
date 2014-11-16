{print} = require 'sys'
{spawn} = require 'child_process'

file = 'cURLCodeGenerator.coffee'

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
