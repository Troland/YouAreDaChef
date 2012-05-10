# A Quick Guide to Using YouAreDaChef

### What YouAreDaChef Does

[YouAreDaChef]yadc is a utility for meta-programming Object-Oriented JavaScript ("JS"). YouAreDaChef supports modifying JavaScript that is written in either a prototype style or a class-oriented style. JavaScript supports extending and redefining methods out of the box. YouAreDaChef takes this further by also supporting [Aspect-Oriented Programming][aop], specifically "decorating" methods with before, after, around, and guard advice.

[yadc]: http://github.com/raganwald/YouAreDaChef
[aop]: https://en.wikipedia.org/wiki/Aspect-oriented_programming

Aspect-Oriented Programming is a *code organization* practice. Its purpose is to separate concerns by responsibility, even when the implementation of that responsibility spans multiple classes or has finer granularity than a method. AOP seeks to avoid *tangling* multiple responsibilities in a single class or method body as well as to avoid *scattering* a single responsibility across several classes.

 YouAreDaChef operates on classes constructed in CoffeeScript with the `class` keyword like this:

	class Muppet
		name: -> @_name
			
	class Animal extends Muppet
		constructor: (@_name) ->
		instrument: -> 'drums'

YouAreDaChef also operates on functions with prototype chains hand-rolled in standard JavaScript like this:

    var Animal, Muppet;

    Muppet = function() {};

    Muppet.prototype.name = function() {
      return this._name;
    };

    Animal = function(_name) {
      this._name = _name;
    };

    Animal.prototype = new Muppet();

    Animal.prototype.instrument = function() {
      return 'drums';
    };

In this document, the words "class" and "method" will be used regardless of how you choose to implement inheritance, and the examples will be given in CoffeeScript for simplicity.

### Basic Syntax

Using YouAreDaChef resembles using jQuery. You start with `YouAreDaChef` and then specify what you wish to "advise." In [Café au Life][cafe], the class `Square` has a method called `set_memo` and another called `initialize`, something like this:

[cafe]: http://recursiveuniver.se

		class Square
			initialize: (args...) ->
				# ...
			set_memo: (index, square) ->
				@memoized[index] = square

In the [garbage collection][gc] module, YouAreDaChef decorates these methods with before and after advice:

[gc]: http://recursiveuniver.se/docs/gc.html

    YouAreDaChef
      .clazz(Square)
        .method('initialize')
          .after ->
            @references = 0
        .method('set_memo')
          .before (index) ->
            if (existing = @get_memo(index))
              existing.decrementReference()
          .after (index, square) ->
            square.incrementReference()
            
As a result, when a Square's `set_memo` method is called, its "before" advice is executed, then its body or "default" advice is executed, then it's "after" advice is executed. If you define more than one before or after advice, they will all be executed in order.

### Some Shortcuts

When you only want to provide one piece of advice to one method, you can use 'compact' syntax for specifying the method name alongside the advice:

    YouAreDaChef
      .clazz(Square)
        .after 'initialize', ->
            @references = 0

You can also save yourself a line of code by treating `YouAreDaChef` as a function (just like `$(...)` in jQuery) and specifying one or more classes as parameters:

    YouAreDaChef(Square)
      .after 'initialize', ->
          @references = 0
          
Before and after advice is passed the same parameters as the 'default' behaviour, but it executed for its side-effects only. There is no way to alter the parameters passed to the default behaviour or to modify its return value.

### Regular Expressions

Instead of using a  method name (or list of method names), you can supply a regular expression to specify the method(s) to be advised. The match data will be passed as the first parameter, so it is possible to use match groups in your advice:

    class EnterpriseyLegume
      setId:         (@id)         ->
      setName:       (@name)       ->
      setDepartment: (@department) ->
      setCostCentre: (@costCentre) ->
    
    YouAreDaChef(EnterpriseyLegume)
      .methods(/set(.*)/)
        .after (match, value) ->
          writeToLog "#{match[1]} set to: #{value}"

### Around Advice

Before and after advice are executed for side-effects only. "Around" advice is all-encompassing: It is passed the parameters and the default advice, and it takes care of calling the default advice and deciding what to return. Here is some fictional code that wraps some methods up in a transaction:

    YouAreDaChef(EnterpriseyLegume)
      .around /set(.*)/, (pointcut, match, value) ->
        performTransaction () ->
          writeToLog "#{match[1]}: #{value}"
          pointcut(value)
          
When multiple around advice is provided, it nests.

### Guard Advice

Ruby on Rails users are familiar with [controller filters][filters]. YouAreDaChef's before, after, and around advices are just like controller filters, except that in Rails, if a before filter returns something falsey, the request cycle is halted. Likewise, Ruby on Rails provides [callbacks][callbacks] for ActiveRecord models. YouAreDaChef works just like the callback queues, every class inherits the before, after, and around advice of its superclasses (or prototypes).

[callbacks]: http://api.rubyonrails.org/classes/ActiveRecord/Callbacks.html
[filters]: http://guides.rubyonrails.org/action_controller_overview.html#filters

Well, YouAreDaChef works *almost* like Ruby on Rails. The one difference is that YouAreDaChef doesn't care what before advice returns. `false`, `null`, `undefined`, it doesn't matter and it doesn't halt the function call. This makes the intent crystal clear: before advice is stuff you want to do before the method call, after advice is stuff you want to do after the method call. Always.

If you want to set up a filter, you want *guard advice*:

    YouAreDaChef(EnterpriseyLegume)
      .when 'setId', (value) ->
        !isNaN(value)
        
`setId` will be aborted if the value passed is not an integer. This pattern of testing for an error and returning the negation of the test value is common, so YouAreDaChef provides a shortcut:

    YouAreDaChef(EnterpriseyLegume)
      .unless 'setId', isNaN