#= require ./jasmine
#= require ./jasmine-html
#= require ./jasmine-jquery-matchers
#= require_tree ./backbone.modelbinding

jasmineEnv = jasmine.getEnv()
jasmineEnv.updateInterval = 1000
trivialReporter = new jasmine.TrivialReporter()
jasmineEnv.addReporter trivialReporter

jasmineEnv.specFilter = (spec) ->
  trivialReporter.specFilter spec

currentWindowOnload = window.onload

window.onload = ->
  currentWindowOnload() if currentWindowOnload
  execJasmine()

execJasmine = ->
  jasmineEnv.execute()
