module player;

import derelict.sdl2.sdl;
import entity;
import statemachine;
import map;

enum MovementState
{
	running,
	standing,
	jumping
}

enum MovementTransition
{
	start,
	stop,
	jump,
	land
}

enum PlayerKeys
{
	left,
	right,
	up,
	down,
	jump,
	attack
}

class Player : Entity
{

	this(Universe* universe)
	{
		this.universe = universe;
		collisionBox.x = -16;
		collisionBox.y = -32;
		collisionBox.w = 32;
		collisionBox.h = 64;
		xVel = 0;
		yVel = 0;
	}

	override void update()
	{
		import std.algorithm : max, min;
		import std.math : abs;
		yVel += universe.gravity;

		if (keyStates[PlayerKeys.left])
		{
			movementState.transition(MovementTransition.start);
			xVel -= movementState == MovementState.jumping ? 0.5 : 0.75;
		}
		else if (keyStates[PlayerKeys.right])
		{
			movementState.transition(MovementTransition.start);
			xVel += movementState == MovementState.jumping ? 0.5 : 0.75;
		}
		else
		{
			if (abs(xVel) >= 2)
				xVel *= 0.75;
			else
			{
				xVel = 0;
				movementState.transition(MovementTransition.stop);
			}
		}

		if (keyStates[PlayerKeys.jump] && movementState != MovementState.jumping)
		{
			yVel = -15;
			movementState.transition(MovementTransition.jump);
		}

		yVel = min(max(-15, yVel), 15);
		xVel = min(max(-10, xVel), 10);
		collisionBox.y += yVel;
		collisionBox.x += xVel;

		checkCollision(collisionBox, universe.map, xVel, yVel);
		if (movementState == MovementState.jumping && yVel == 0)
		{
			movementState.transition(MovementTransition.land);
			if (xVel != 0)
				movementState.transition(MovementTransition.start);
		}
	}

	override void handleInput(const(SDL_Event*) event)
	{
		debug import std.stdio : writeln;
		if (event.type != SDL_KEYDOWN && event.type != SDL_KEYUP)
			return;
		switch (event.key.keysym.sym)
		{
		case SDLK_LCTRL:
		case SDLK_RCTRL:
//			debug writeln("ctrl pressed");
			keyStates[PlayerKeys.jump] = event.key.type == SDL_KEYDOWN;
			break;
		case SDLK_LALT:
		case SDLK_RALT:
//			debug writeln("alt pressed");
			keyStates[PlayerKeys.attack] = event.key.type == SDL_KEYDOWN;
			break;
		case SDLK_LEFT:
//			debug writeln("left pressed");
			keyStates[PlayerKeys.left] = event.key.type == SDL_KEYDOWN;
			break;
		case SDLK_RIGHT:
//			debug writeln("right pressed");
			keyStates[PlayerKeys.right] = event.key.type == SDL_KEYDOWN;
			break;
		case SDLK_DOWN:
//			debug writeln("down pressed");
			keyStates[PlayerKeys.down] = event.key.type == SDL_KEYDOWN;
			break;
		case SDLK_UP:
//			debug writeln("up pressed");
			keyStates[PlayerKeys.up] = event.key.type == SDL_KEYDOWN;
			break;
		default:
			break;
		}
	}

	override void draw(SDL_Renderer* renderer)
	{
		SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND);
		// Collision box in blue
		SDL_SetRenderDrawColor(renderer, 0, 0, 255, 128);
		SDL_RenderFillRect(renderer, &collisionBox);

		// Hurt boxes in green
		SDL_SetRenderDrawColor(renderer, 0, 255, 0, 128);
		foreach (i, ref box; hurtBoxes)
		{
			if (1 << i & hurtActive)
				SDL_RenderFillRect(renderer, &box);
		}

		// Hit boxes in red
		SDL_SetRenderDrawColor(renderer, 255, 0, 0, 128);
		foreach (i, ref box; hitBoxes)
		{
			if (1 << i & hitActive)
				SDL_RenderFillRect(renderer, &box);
		}
	}

	SDL_Rect collisionBox;

private:
	alias PlayerStateMachine = StateMachine!(MovementState, MovementTransition,
		MovementTransition.jump, MovementState.running, MovementState.jumping,
		MovementTransition.jump, MovementState.standing, MovementState.jumping,
		MovementTransition.start, MovementState.jumping, MovementState.jumping,
		MovementTransition.start, MovementState.running, MovementState.running,
		MovementTransition.start, MovementState.standing, MovementState.running,
		MovementTransition.stop, MovementState.running, MovementState.standing,
		MovementTransition.stop, MovementState.jumping, MovementState.jumping,
		MovementTransition.land, MovementState.jumping, MovementState.standing);
	PlayerStateMachine movementState = PlayerStateMachine(MovementState.standing);
	float xVel;
	float yVel;

	SDL_Rect[8] hitBoxes;
	SDL_Rect[8] hurtBoxes;
	bool[PlayerKeys.max + 1] keyStates;
	ubyte hitActive;
	ubyte hurtActive;
	Universe* universe;
}
