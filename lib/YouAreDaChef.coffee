_ = require 'underscore'

_.defaults this,
  YouAreDaChef: (clazzes...) ->

    pointcuts = (pointcut_exprs) ->
      _.tap {}, (cuts) ->
        _.each clazzes, (clazz) ->
          _.each pointcut_exprs, (expr) ->
            if _.isString(expr) and _.isFunction(clazz.prototype[expr])
              name = expr
              cuts[name] =
                clazz: clazz
                pointcut: clazz.prototype[name]
                inject: []
            else if expr instanceof RegExp
              _.each _.functions(clazz.prototype), (name) ->
                if match = name.match(expr)
                  cuts[name] =
                    clazz: clazz
                    pointcut: clazz.prototype[name]
                    inject: match

    combinator =

      before: (pointcut_exprs..., advice) ->
        _.each pointcuts(pointcut_exprs), ({clazz, pointcut, inject}, name) ->
          clazz.prototype[name] = (args...) ->
            advice.call(this, inject..., args...)
            pointcut.apply(this, args)
        combinator

      # kestrel
      after: (pointcut_exprs..., advice) ->
        _.each pointcuts(pointcut_exprs), ({clazz, pointcut, inject}, name) ->
          clazz.prototype[name] = (args...) ->
            _.tap pointcut.apply(this, args), =>
              advice.call(this, inject..., args...)
        combinator

      # cardinal combinator
      around: (pointcut_exprs..., advice) ->
        _.each pointcuts(pointcut_exprs), ({clazz, pointcut, inject}, name) ->
          clazz.prototype[name] = (args...) ->
            bound_pointcut = (args2...) =>
              pointcut.apply(this, args2)
            advice.call(this, bound_pointcut, inject..., args...)
        combinator

      # bluebird
      guard: (pointcut_exprs..., advice) ->
        _.each pointcuts(pointcut_exprs), ({clazz, pointcut, inject}, name) ->
          clazz.prototype[name] = (args...) ->
            pointcut.apply(this, args) if advice.call(this, inject..., args...)
        combinator