module player;

import derelict.sdl2.sdl;
import entity;
import statemachine;
import map;

enum PlayerKeys
{
	left,
	right,
	up,
	down,
	jump,
	attack
}

enum AttackDirection
{
	up,
	upRight,
	right,
	downRight,
	down,
	downLeft,
	left,
	upLeft
}

class Player : Entity
{

	this(SDL_Texture* texture, Universe* universe)
	{
		this.texture = texture;

		component.universe = universe;
		component.collisionBox.x = -16;
		component.collisionBox.y = -32;
		component.collisionBox.w = 32;
		component.collisionBox.h = 64;

		component.hitBoxes[AttackDirection.right].w = 32;
		component.hitBoxes[AttackDirection.right].h = 32;
		component.hitBoxes[AttackDirection.right].x = 32;
		component.hitBoxes[AttackDirection.right].y = 16;

		component.hitBoxes[AttackDirection.left].w = 32;
		component.hitBoxes[AttackDirection.left].h = 32;
		component.hitBoxes[AttackDirection.left].x = -32;
		component.hitBoxes[AttackDirection.left].y = 16;

		component.hurtBoxes[0].w = 20;
		component.hurtBoxes[0].h = 60;
		component.hurtBoxes[0].x = 0;
		component.hurtBoxes[0].y = 4;

		component.hurtMask = 1;

		component.xVel = 0;
		component.yVel = 0;

		component.health = 200;
	}

	override void update()
	{
		import std.algorithm : max, min;
		import std.math : abs;

		if (component.screenKill())
		{
			dead = true;
			return;
		}

		component.yVel += component.universe.gravity;

		if (keyStates[PlayerKeys.left])
		{
			movementState.transition(MovementTransition.start);
			component.xVel -= movementState == MovementState.jumping ? 0.5 : 0.75;
			component.facing = Facing.left;
		}
		else if (keyStates[PlayerKeys.right])
		{
			movementState.transition(MovementTransition.start);
			component.xVel += movementState == MovementState.jumping ? 0.5 : 0.75;
			component.facing = Facing.right;
		}
		else
		{
			if (abs(component.xVel) >= 2)
				component.xVel *= 0.75;
			else
			{
				component.xVel = 0;
				movementState.transition(MovementTransition.stop);
			}
		}

		if (keyStates[PlayerKeys.jump] && movementState != MovementState.jumping)
		{
			component.yVel = -15;
			movementState.transition(MovementTransition.jump);
		}

		component.yVel = min(max(-15, component.yVel), 15);
		component.xVel = min(max(-10, component.xVel), 10);
		component.collisionBox.y += component.yVel;
		component.collisionBox.x += component.xVel;

		checkCollision(component.collisionBox, component.universe.map, component.xVel, component.yVel);
		if (movementState == MovementState.jumping && component.yVel == 0)
		{
			movementState.transition(MovementTransition.land);
			if (component.xVel != 0)
				movementState.transition(MovementTransition.start);
		}

		handleAttack();

		component.handleInjury();
		if (component.health == 0)
		{
			if (!dead)
			{
				import std.stdio : writeln;
				writeln("Player died");
				dead = true;
			}
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
		int frameX;
		int frameY;
		if (component.facing == Facing.left)
		{
			frameY = 0;
		}
		else
		{
			frameY = 1;
		}

		SDL_Rect src;
		SDL_Rect dst;

		src.h = 64;
		src.y = 64 * frameY;

		dst.h = 64;
		dst.y = component.collisionBox.y;

		if (component.hitMask == 0 || component.hitLag <= 4)
		{
			src.x = 64 * frameX;
			src.w = 64;
			dst.w = 64;
			dst.x = component.collisionBox.x - 16;
		}
		else
		{
			src.x = 128;
			src.w = 128;
			dst.w = 128;
			dst.x = component.collisionBox.x - 16 - 32;
		}

		SDL_RenderCopy(renderer, texture, &src, &dst);

//		component.draw(renderer);
	}

	void handleAttack()
	{
		if (component.hitLag > 0)
			component.hitLag--;
		else
		{
			if (keyStates[PlayerKeys.attack])
			{
				component.hitLag = 10;
				// 7 0 1
				// 6   2
				// 5 4 3
				component.hitMask = 1 << (component.facing == Facing.left ? 6 : 2);
			}
			else
				component.hitMask = 0;
		}
	}



	override int checkHitBoxes(ref const SDL_Rect[8] hurtBoxes, ubyte mask)
	{
		return component.checkHitBoxes(hurtBoxes, mask);
	}

	CombatComponent component;

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
	bool[PlayerKeys.max + 1] keyStates;
	SDL_Texture* texture;
}
