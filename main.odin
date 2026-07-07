#+feature dynamic-literals

package main

import "core:math/rand"
import "core:math"
import "core:fmt"
import rl "vendor:raylib"

width : i32 : 1280
height : i32 : 720
gravity : f32 : 400
Vector2 :: [2]f32
Vector4 :: [4]f32

radius : f32 = 32
loss : f32 = 0.82
numb_balls : u32: 22

ball :: struct{
    pos: Vector2,
    vel: Vector2,
    rad:f32,
    col: rl.Color
}

main :: proc() {

    fmt.println("Hellope!")

    rl.SetTargetFPS(60)
    rl.InitWindow(width, height, "Oding Test")
    defer rl.CloseWindow()
   
    balls : [numb_balls]ball

    for i in 0..< numb_balls {
        my_ball := ball{
            pos = Vector2{rand.float32_range(cast(f32)width/8,cast(f32)width/2), rand.float32_range(cast(f32)height/8,cast(f32)height/2)},
            vel = Vector2{rand.float32_range(-1000,1000), rand.float32_range(-1000,1000)},
            rad = rand.float32_range(20,40),
            col = rl.ColorFromHSV(rand.float32_range(0,360), 1, 1)
        }
        balls[i]=my_ball
    }


    for !rl.WindowShouldClose(){
        dt := rl.GetFrameTime()

        rl.BeginDrawing()
        rl.ClearBackground(rl.GRAY);

        for &ball in balls
        {
	    
            ball.pos += ball.vel*dt
	  
            ball.vel.y += gravity*dt

            nx :=  ball.pos.x+ball.vel.x*dt
            ny :=  ball.pos.y+ball.vel.y*dt

            if nx-ball.rad< cast(f32)0 || nx +ball.rad> cast(f32)width {
                ball.vel.x *= -0.82
            //    ball.col =  rl.ColorFromHSV(rand.float32_range(0,360), 1, 1)
            }
            else do ball.pos.x = nx

            if ny-ball.rad< cast(f32)0 || ny+ball.rad > cast(f32)height {
               // ball.col =  rl.ColorFromHSV(rand.float32_range(0,360), 1, 1)
                ball.vel.y *= -0.82
            }
            else do ball.pos.y = ny

            //Check Collision

            for &other_ball in balls
            {
                if ball == other_ball do continue

                if rl.CheckCollisionCircles(ball.pos, ball.rad, other_ball.pos,other_ball.rad){



                    dist := ball.rad +other_ball.rad

                    real_dist := math.sqrt(math.pow_f32(ball.pos.x - other_ball.pos.x, 2) + math.pow_f32(ball.pos.y - other_ball.pos.y,2))

                    overlap := dist - real_dist


                    mult_vel : Vector2 = {0,0} * overlap
                    //if overlap > dist*0.2 do mult_vel = { ball.pos.x - other_ball.pos.x, ball.pos.y - other_ball.pos.y} * overlap/dist

                    vel := ball.vel + mult_vel
                    ball.vel = other_ball.vel + mult_vel
                    other_ball.vel = vel

                }

            }

            rl.DrawCircleV(ball.pos, ball.rad, ball.col)

        }
        rl.EndDrawing()


    }



}
