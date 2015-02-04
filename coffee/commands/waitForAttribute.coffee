events = require('events');

#This custom command allows us to locate an HTML element on the page and
#then wait until the value of a specified attribute matches the provided
#expression (aka. the 'checker' function).
#It retries executing the checker function every 100ms until either
#it evaluates to true or it reaches maxTimeInMilliseconds (which fails
#the test). Nightwatch uses the Node.js EventEmitter pattern to handle
#asynchronous code so this command is also an EventEmitter.

class WaitForAttribute extends events.EventEmitter
	constructor: ->
		super;
		@startTimeInMilliseconds = null;
		@timeoutRetryInMilliseconds = 100;

	command: (element, attribute, checker, timeoutInMilliseconds) ->
		@startTimeInMilliseconds = new Date().getTime();

		if typeof timeoutInMilliseconds != 'number'
			timeoutInMilliseconds = @api.globals.waitForConditionTimeout;

		@check(element, attribute, checker, (result, loadedTimeInMilliseconds) =>
			if result
				message = "waitForAttribute: #{element}@#{attribute}.
					Expression was true after #{loadedTimeInMilliseconds - @startTimeInMilliseconds}.";
			else
				message = "waitForAttribute: #{element}@#{attribute}.
					Expression wasn't true in #{timeoutInMilliseconds} ms.";
			
			@client.assertion(result, 'expression false', 'expression true', message, true);
			@emit('complete');
		, timeoutInMilliseconds);

		return this;

	check: (element, attribute, checker, callback, maxTimeInMilliseconds) ->
		@api.getAttribute(element, attribute, (result) =>
			now = new Date().getTime();
			if result.status == 0 && checker(result.value)
				callback(true, now);
			else if now - @startTimeInMilliseconds < maxTimeInMilliseconds
				setTimeout(=>
					@check(element, attribute, checker, callback, maxTimeInMilliseconds);
				, @timeoutRetryInMilliseconds);
			else
				callback(false);
		);

module.exports = WaitForAttribute;