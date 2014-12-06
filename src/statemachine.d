module statemachine;

/**
 * Implements a $(LINK2 http://en.wikipedia.org/wiki/Finite-state_machine, finite state machine).
 *
 * The size of the state machine in memory is the same as the size of the StateType type. Information
 * about state transitions is converted into code at compile time.
 */
struct StateMachine(StateType, TransitionType, Args...)
	if (is (StateType == enum) && is (TransitionType == enum) && Args.length % 3 == 0)
{
public:

	/**
	 * Params:
	 *     initial = the initial state of the machine
	 */
	this(StateType initial)
	{
		_currentState = initial;
	}

	/**
	 * Attempts to perform the given transition.
	 * Params:
	 *     transition = the transition to perform
	 * Returns:
	 *     true if the transition succeeded, false if it was invalid
	 */
	bool transition(TransitionType transition) nothrow @safe @nogc
	{
//		debug pragma (msg, generateTransitions());
		mixin (generateTransitions());
	}

	bool opEquals(StateType state) const nothrow @safe @nogc
	{
		return _currentState == state;
	}

	/**
	 * Returns:
	 *     the current state
	 */
	StateType currentState() const nothrow @property @safe @nogc
	{
		return _currentState;
	}

private:

	static string generateTransitions()
	{
		import std.typetuple:staticMap;
		import std.algorithm : sort, uniq;
		import std.array:array;
		import std.conv:to;
		enum groupCount = Args.length / 3;
		string result = "switch (transition)\n{\n";
		string[3][] groups = new string[3][](groupCount);
		foreach (I, Arg; Args)
		{
			static if (I % 3 == 0)
			{
				groups[I / 3][0] = Args[I + 0].to!string;
				groups[I / 3][1] = Args[I + 1].to!string;
				groups[I / 3][2] = Args[I + 2].to!string;
			}
		}
		groups = groups.sort!((a, b) => a[0] < b[0] || (a[0] == b[0] && a[1] < b[1])
			|| (a[0] == b[0] && a[1] == b[1] && a[2] < b[2])).uniq().array();
		foreach (size_t i, string[3] group; groups)
		{
			if (i == 0 || groups[i - 1][0] != group[0])
			{
				result ~= "case TransitionType." ~ group[0] ~ ":\n";
				result ~= "\tswitch(_currentState)\n";
				result ~= "\t{\n";
			}
			result ~= "\tcase StateType." ~ group[1] ~ ": _currentState = StateType." ~ group[2] ~ "; return true;\n";
			if (i + 1 >= groups.length || groups[i + 1][0] != group[0])
			{
				result ~= "\tdefault: return false;\n";
				result ~= "\t}\n";
			}
		}
		result ~= "default: return false;\n}\n";
		return result;
	}

	StateType _currentState;
}

///
unittest
{
	import std.stdio:writeln;
	enum States { Taxiing, Stopped, Flying }
	enum Transitions { Land, Takeoff, Park, Startup }
	auto stateMachine = StateMachine!(States, Transitions,
		Transitions.Land, States.Flying, States.Taxiing,
		Transitions.Takeoff, States.Taxiing, States.Flying,
		Transitions.Park, States.Taxiing, States.Stopped,
		Transitions.Startup, States.Stopped, States.Taxiing)(States.Stopped);
	assert (stateMachine.currentState == States.Stopped);
	assert (!stateMachine.transition(Transitions.Takeoff));
	assert (!stateMachine.transition(Transitions.Land));
	assert (stateMachine.transition(Transitions.Startup));
	assert (stateMachine.currentState == States.Taxiing);
	assert (!stateMachine.transition(Transitions.Startup));
}
