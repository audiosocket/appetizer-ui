#= require json2
#= require jquery
#= require underscore
#= require underscore.string

#= require backbone
#= require backbone.modelbinding

#= require appetizer/core
#= require appetizer/model
#= require appetizer/view

# Mixin non-conflicting methods to underscore.

_.mixin _.str.exports()
