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

ball_damp : f32 : 0.95
wall_damp : f32 : 0.8

numb_balls: u32 : 200

ball :: struct {
	pos: Vector2,
	vel: Vector2,
	rad: f32,
    normal_rad : f32,
	col: rl.Color,
    id: u32,
}

clicked_id : u32 = 0
left_down : bool

main :: proc() {

	fmt.println("Hellope!")

    rl.SetConfigFlags({.WINDOW_RESIZABLE})

	rl.SetTargetFPS(120)
	rl.InitWindow(WIDTH, HEIGHT, "Oding Test")
    rl.SetWindowMinSize(320, 240)
	defer rl.CloseWindow()

	balls: [dynamic]ball
    defer delete(balls)

    //Start balls
	for i in 0 ..< numb_balls {

        radius := rand.float32_range(10, 20)
		my_ball := ball {
			pos = Vector2 {
				rand.float32_range(cast(f32)width / 8, cast(f32)width / 2),
				rand.float32_range(cast(f32)height / 8, cast(f32)height / 2),
			},
			vel = Vector2{rand.float32_range(-1000, 1000), rand.float32_range(-1000, 1000)},
			rad = radius,
            normal_rad = radius,
			col = rl.ColorFromHSV(rand.float32_range(0, 360), 1, 1),
            id = i+1
		}
        append(&balls, my_ball)
	}

    
    window_position := rl.GetWindowPosition()

    t : f32 = 0

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(rl.GRAY)
        w_dt := window_position - rl.GetWindowPosition()
		dt := rl.GetFrameTime()
        window_position = rl.GetWindowPosition()
        rl.DrawText(rl.TextFormat("Number of Balls: %i", len(balls)), 10, 10, 20, rl.RED)
        
        width := cast(f32)rl.GetScreenWidth()  
        height := cast(f32)rl.GetScreenHeight() 


        if rl.IsMouseButtonDown(.RIGHT) {
            t -= dt
            if t < 0 {
                radius := rand.float32_range(10, 20)
                my_ball := ball {
                    pos = rl.GetMousePosition(),
                    vel = Vector2{0,0},
                    rad = radius,
                    normal_rad = radius,
                    col = rl.ColorFromHSV(rand.float32_range(0, 360), 1, 1),
                    id = cast(u32)len(balls) + 1
                }
                append(&balls, my_ball)

                t = 0.01
                
            }
            

        }      
        if rl.IsMouseButtonPressed(.LEFT) do left_down = true
        if rl.IsMouseButtonReleased(.LEFT) {
            left_down = false
            clicked_id = 0
        } 

        //balls logic
		for &ball in balls {
            if clicked_id == 0 && left_down {
				if rl.CheckCollisionCircles(ball.pos, ball.rad, rl.GetMousePosition(), ball.rad) {
                   clicked_id = ball.id 
                    
                }
            }
            
           	for &other_ball in balls {
				if ball == other_ball do continue
				if rl.CheckCollisionCircles(ball.pos, ball.rad, other_ball.pos, other_ball.rad) {
                    resolveColision(&ball,&other_ball)
				}

			}
            resolveWallCollision(&ball, dt,width,height)


            if ball.id != clicked_id{
                ball.pos += ball.vel * dt + w_dt
                ball.vel.y += gravity * dt
                ball.pos += ball.vel* dt

                if ball.rad > ball.normal_rad do ball.rad -= dt*5
                
            }
            else {
                ball.vel = (rl.GetMousePosition() - ball.pos)*2
                ball.pos += ball.vel * 5 * dt + w_dt
                ball.rad += dt*10
            }

			rl.DrawCircleV(ball.pos, ball.rad, ball.col)

		}
		rl.EndDrawing()


	}

}



resolveWallCollision :: proc(ball :^ball, dt :f32, width,height :f32) {

    if ball.pos.x + cast(f32)ball.rad > width{
        ball.vel.x *= -wall_damp
        ball.pos.x -= ball.pos.x + cast(f32)ball.rad - width
    }
    else if ball.pos.x - cast(f32)ball.rad < 0 {
        ball.vel.x *= -wall_damp
        ball.pos.x -= (ball.pos.x - cast(f32)ball.rad)
    }
    if ball.pos.y + cast(f32)ball.rad >height{
        ball.vel.y *= -wall_damp
        ball.pos.y -= ball.pos.y + cast(f32)ball.rad - height
    }

   // Not adding upper bound
   // else if ball.pos.y - cast(f32)ball.rad < 0{
   //     ball.vel.y *= -wall_damp
   //     ball.pos.y -= (ball.pos.y - cast(f32)ball.rad)
   // }

}

resolveColision :: proc(ball_a, ball_b :^ball  ){

    
             
    mass_a := math.PI* math.pow(ball_a.rad,2)
    mass_b := math.PI* math.pow(ball_b.rad,2)
    
    min_dist := ball_a.rad +ball_b.rad
    delta := ball_a.pos - ball_b.pos
    real_dist := math.sqrt(math.pow(delta.x, 2) + math.pow(delta.y,2))

    if real_dist >= min_dist do return; 

    overlap := min_dist - real_dist
    total_mass := mass_a + mass_b

    if real_dist == 0.0 {
        delta = Vector2{0.01,0}
        real_dist = 0.01; 
    }

    normal : Vector2 = delta/real_dist

    correctionA : Vector2 = normal *(-overlap * (mass_b / total_mass))
    correctionB : Vector2 = normal *( overlap * (mass_a / total_mass))
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

    impulseMag := - (1 + ball_damp)* velAlongNormal/ (1/mass_a + 1/mass_b)
    impulse : Vector2 = normal * impulseMag

    ball_a.vel += impulse/mass_a 
    ball_b.vel -= impulse/mass_b
   
}

