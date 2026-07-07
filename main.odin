#+feature dynamic-literals

package main

import "core:fmt"
import "core:math"
import "core:math/rand"
import rl "vendor:raylib"



HEIGHT: i32 : 720
WIDTH: i32 : 1280

width: i32 = 1280
height: i32 = 720

gravity: f32 : 400
Vector2 :: [2]f32
Vector4 :: [4]f32

window_position : Vector2
loss: f32 = 0.82
numb_balls: u32 : 2000

ball :: struct {
	pos: Vector2,
	vel: Vector2,
	rad: f32,
    mass: f32,
	col: rl.Color,
}

main :: proc() {

	fmt.println("Hellope!")

    rl.SetConfigFlags({.WINDOW_RESIZABLE})

	rl.SetTargetFPS(60)
	rl.InitWindow(WIDTH, HEIGHT, "Oding Test")
    rl.SetWindowMinSize(320, 240)
	defer rl.CloseWindow()

	balls: [numb_balls]ball

	for i in 0 ..< numb_balls {

        radius := rand.float32_range(10, 15)
		my_ball := ball {
			pos = Vector2 {
				rand.float32_range(cast(f32)width / 8, cast(f32)width / 2),
				rand.float32_range(cast(f32)height / 8, cast(f32)height / 2),
			},
			vel = Vector2{rand.float32_range(-1000, 1000), rand.float32_range(-1000, 1000)},
			rad = radius,
            mass = math.PI* math.pow(radius,2),
			col = rl.ColorFromHSV(rand.float32_range(0, 360), 1, 1),
		}
		balls[i] = my_ball
	}

    
	for !rl.WindowShouldClose() {
        window_position = rl.GetWindowPosition()
        rl.DrawText(rl.TextFormat("Position: %.0f, %.0f", window_position.x, window_position.y), 10, 10, 20, rl.DARKGRAY)
        
        width = rl.GetScreenWidth()  
        height = rl.GetScreenHeight() 
        

        
		dt := rl.GetFrameTime()

		rl.BeginDrawing()
		rl.ClearBackground(rl.GRAY)

        //balls logic
		for &ball in balls {
            ball.pos += ball.vel * dt
            ball.vel.y += gravity * dt

			for &other_ball in balls {
				if ball == other_ball do continue
				if rl.CheckCollisionCircles(ball.pos, ball.rad, other_ball.pos, other_ball.rad) {
                    resolveColision(&ball,&other_ball)
				}

			}

            resolveWallCollision(&ball, dt)

			rl.DrawCircleV(ball.pos, ball.rad, ball.col)

		}
		rl.EndDrawing()


	}

}



resolveWallCollision :: proc(ball :^ball, dt :f32) {
    nx := ball.pos.x + ball.vel.x * dt
    ny := ball.pos.y + ball.vel.y * dt

    ball.pos.x += ball.vel.x * dt
    ball.pos.y += ball.vel.y * dt  

    global_bpos : Vector2 = {ball.pos.x + window_position.x, ball.pos.y + window_position.y}
    global_wpos : Vector2 = {cast(f32)width + window_position.x, cast(f32)height + window_position.y}
//
//    if nx - ball.rad < cast(f32)0 +window_position.x|| nx + ball.rad > cast(f32)width +window_position.x{
//        ball.vel.x *= -0.82
//    } else do ball.pos.x = nx
//
//    if ny - ball.rad < cast(f32)0+window_position.y || ny + ball.rad > cast(f32)height +window_position.y{
//        ball.vel.y *= -0.82
//    } else do ball.pos.y = ny


    if global_bpos.x + cast(f32)ball.rad > global_wpos.x{
        ball.vel.x *= -0.82
        ball.pos.x -= global_bpos.x + cast(f32)ball.rad - global_wpos.x
    }
    else if global_bpos.x - cast(f32)ball.rad < window_position.x {
        ball.vel.x *= -0.82
        ball.pos.x -= (global_bpos.x - cast(f32)ball.rad) - window_position.x
    }
    if global_bpos.y + cast(f32)ball.rad > global_wpos.y{
        ball.vel.y *= -0.82
        ball.pos.y -= global_bpos.y + cast(f32)ball.rad - global_wpos.y
    }
    else if global_bpos.y - cast(f32)ball.rad < window_position.y {
        ball.vel.y *= -0.82
        ball.pos.y -= (global_bpos.y - cast(f32)ball.rad)  - window_position.y
    }

}

resolveColision :: proc(ball_a, ball_b :^ball  ){

    min_dist := ball_a.rad +ball_b.rad
    delta := ball_a.pos - ball_b.pos
    real_dist := math.sqrt(math.pow(delta.x, 2) + math.pow(delta.y,2))

    if real_dist >= min_dist do return; 

    overlap := min_dist - real_dist
    total_mass := ball_a.mass + ball_b.mass

    if real_dist == 0.0 {
        delta = Vector2{0.01,0}
        real_dist = 0.01; 
    }

    normal : Vector2 = delta/real_dist

    correctionA : Vector2 = normal *(-overlap * (ball_b.mass / total_mass))
    correctionB : Vector2 = normal *( overlap * (ball_a.mass / total_mass))
    ball_a.pos -= correctionA
    ball_b.pos -= correctionB

    //Va2 = (ma - mb)/(ma+mb) * va1 + 2mb/(ma+mb)*Vb1 
    //Vb2 = 2ma/(ma+mb) * va1 + (ma+mb)/(ma+mb)*Vb1 

//    new_va :=   (ball_a.mass - ball_b.mass) * ball_a.vel/total_mass + 2*ball_b.mass*ball_b.vel/total_mass
//    new_vb :=   2*ball_a.mass*ball_a.vel/total_mass + (ball_b.mass - ball_a.mass) * ball_b.vel/total_mass
//
//    ball_a.vel = new_va*0.98
//    ball_b.vel = new_vb*0.98


    relVel : Vector2 = ball_a.vel- ball_b.vel
    velAlongNormal : f32 = relVel.x * normal.x + relVel.y*normal.y

    if velAlongNormal > 0.0 do return;
 
    restitution : f32 = 1

    impulseMag := - (1 + restitution)* velAlongNormal/ (1/ball_a.mass + 1/ball_b.mass)
    impulse : Vector2 = normal * impulseMag

    ball_a.vel += impulse/ball_a.mass 
    ball_b.vel -= impulse/ball_b.mass
 
   

}
