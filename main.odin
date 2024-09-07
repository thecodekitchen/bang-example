package bang_example

import "core:strings"
import "core:fmt"
import "core:math"
import "core:math/linalg"
import glfw "vendor:glfw"
import "core:time"

import "../bang"
// in seconds
FRAME_DURATION :: time.Duration(0.016 * f64(time.Second))
MOUSE_SENSITIVITY :: 0.05
MOVE_SPEED :: 0.25



main :: proc() {
    // Stage
    window, sg := bang.create_scene()

    cube_mesh, cube_material_data := bang.build_mesh_component("assets/cube.obj")

    if cube_material_data == nil {
        bang.error("failed to load materials for cube.obj", .NilPtr)
        return
    }
    cube_material, err := bang.build_advanced_material(cube_material_data.?)
    if !bang.ok(err) {
        bang.error("failed to build cube material", err.t)
        return
    }

    floor_material_data := bang.MaterialData{
        ambient = {0,1,0},
        diffuse = {0,1,0},
        specular = {0,1,0},
        shininess = 5,
    }

    floor_material, floor_err := bang.build_advanced_material(floor_material_data)
    if !bang.ok(floor_err) {
        bang.error("failed to build floor material", err.t)
        return
    }
    floor_transform := bang.default_transform("floor")
    floor_transform.position = {0,-0.5,0}
    floor_transform.scale = {10,1,10}
    floor_eid, _ := bang.add_entity_to_scene(&sg, [](^bang.Component){&cube_mesh, &cube_material, &floor_transform})

    pos_x_wall_material_data := bang.MaterialData{
        ambient = {1,0,0},
        diffuse = {1,0,0},
        specular = {1,0,0},
        shininess = 5,
    }

    pos_x_wall_material, posx_err := bang.build_advanced_material(pos_x_wall_material_data)
    if !bang.ok(posx_err) {
        bang.error("failed to build pos_x_wall material", err.t)
        return
    }
    pos_x_wall_transform := bang.default_transform("pos_x_wall")
    pos_x_wall_transform.position = {5,0,0}
    pos_x_wall_transform.scale = {1,10,10}
    pos_x_wall_mesh := cube_mesh
    // pos_x_wall_material := cube_material
    pos_x_wall_eid, _ := bang.add_entity_to_scene(&sg, [](^bang.Component){&pos_x_wall_mesh, &pos_x_wall_material, &pos_x_wall_transform})

    neg_x_wall_material_data := bang.MaterialData{
        ambient = {0,0,1},
        diffuse = {0,0,1},
        specular = {0,0,1},
        shininess = 5,
    }

    neg_x_wall_material, negx_err := bang.build_advanced_material(neg_x_wall_material_data)
    if !bang.ok(negx_err) {
        bang.error("failed to build neg_x_wall material", err.t)
        return
    }
    neg_x_wall_transform := bang.default_transform("neg_x_wall")
    neg_x_wall_transform.position = {-5,0,0}
    neg_x_wall_transform.scale = {1,10,10}
    neg_x_wall_mesh := cube_mesh
    neg_x_wall_eid, _ := bang.add_entity_to_scene(&sg, [](^bang.Component){&neg_x_wall_mesh, &neg_x_wall_material, &neg_x_wall_transform})

    pos_z_wall_transform := bang.default_transform("pos_z_wall")
    pos_z_wall_transform.position = {0,0,5}
    pos_z_wall_transform.scale = {10,10,1}
    pos_z_wall_mesh := cube_mesh
    pos_z_wall_material := cube_material
    pos_z_wall_eid, _ := bang.add_entity_to_scene(&sg, [](^bang.Component){&pos_z_wall_mesh, &pos_z_wall_material, &pos_z_wall_transform})

    neg_z_wall_transform := bang.default_transform("neg_z_wall")
    neg_z_wall_transform.position = {0,0,-5}
    neg_z_wall_transform.scale = {10,10,1}
    neg_z_wall_mesh := cube_mesh
    neg_z_wall_material := cube_material
    neg_z_wall_eid, _ := bang.add_entity_to_scene(&sg, [](^bang.Component){&neg_z_wall_mesh, &neg_z_wall_material, &neg_z_wall_transform})

    ceiling_transform := bang.default_transform("ceiling")
    ceiling_transform.position = {0,5,0}
    ceiling_transform.scale = {10,1,10}
    ceiling_mesh := cube_mesh
    ceiling_material := cube_material
    ceiling_eid, _ := bang.add_entity_to_scene(&sg, [](^bang.Component){&ceiling_mesh, &ceiling_material, &ceiling_transform})

    bang.debug_log("added walls to scene")
    // Actors
    player_mesh, ball_material_data := bang.build_mesh_component("assets/ball.obj")

    if ball_material_data == nil {
        bang.error("failed to load materials for ball.obj", .NilPtr)
        return
    }
    ball_material, mat_err := bang.build_advanced_material(ball_material_data.?)
    if !bang.ok(mat_err) {
        bang.error("failed to build ball material", err.t)
        return
    }
    player_transform := bang.default_transform("player")
    player_transform.position = {-2,2,0}
    player_eid, player_err := bang.add_entity_to_scene(&sg, [](^bang.Component){&player_mesh, &ball_material, &player_transform})
    if !bang.ok(player_err) {
        fmt.println("failed to add ball to scene")
        return
    }
    bang.debug_log("added player to scene")

    sg.Systems["player_controller"] = proc(sg:^bang.SceneGraph) -> bang.Error {
        transform := bang.get_transform_by_name(sg, "player")
        if transform == nil {
            message := fmt.tprintf("failed to get transform for player with name: %s", "player")
            return bang.error(message, .NilPtr)
        }
        if(bang.get_key_down(sg.InputManager, "w")) {
            transform.position.z += MOVE_SPEED
        }
        if(bang.get_key_down(sg.InputManager, "s")) {
            transform.position.z -= MOVE_SPEED
        }
        if(bang.get_key_down(sg.InputManager, "a")) {
            transform.position.x -= MOVE_SPEED
        }
        if(bang.get_key_down(sg.InputManager, "d")) {
            transform.position.x += MOVE_SPEED
        }
        if(bang.get_key_down(sg.InputManager, "space")) {
            transform.position.y += MOVE_SPEED
        }
        if(bang.get_key_down(sg.InputManager, "left_shift")) {
            transform.position.y -= MOVE_SPEED
        }

        return bang.good()
    }
    
    // Lights
    white_light := bang.Light{
        ctype = .Light,
        color = {1,1,1},
        position = {0,5,5},
        intensity = 1.0
    }
    light_eid, light_err := bang.add_entity_to_scene(&sg, [](^bang.Component){&white_light})
    if !bang.ok(err) {
        fmt.println("failed to add light to scene")
        return
    }
    bang.debug_log("added light to scene")


    
    // red_light := Light{
    //     color = {1,0,0},
    //     position = {5,5,5}
    // }
    // blue_light := Light{
    //     color = {0,0,1},
    //     position = {-5,5,5}
    // }
    // add_entity_to_scene(&sg, [](^Component){&blue_light, &red_light})

    // Camera
    cam_transform := bang.default_transform()

    cam_transform.position = {0,2,5}
    main_cam, cam_err := bang.build_camera(&sg, &cam_transform, true)
    if !bang.ok(cam_err) {
        fmt.println("failed to build camera")
        return
    }
    
    cam_eid, eid_err := bang.add_entity_to_scene(&sg, [](^bang.Component){&cam_transform, &main_cam})
    if !bang.ok(cam_err) {
        fmt.println("failed to add camera to scene")
        return
    }
    bang.debug_log("added camera to scene")
    sg.Renderer.projection_matrix = main_cam.projection_matrix
    sg.Renderer.view_matrix = main_cam.view_matrix

    sg.Systems["camera_controller"] = proc(sg: ^bang.SceneGraph) -> bang.Error {
        cam_t := bang.get_main_camera_transform(sg)
        
        if cam_t == nil {
            bang.error("failed to get camera transform", .NilPtr)
        }
        player_transform := bang.get_transform_by_name(sg, "player")
        if player_transform == nil {
            bang.error("failed to get player transform", .NilPtr)
        }

        bang.look_at(cam_t, player_transform.position)

        return bang.good()
    }
    // sg.Systems["cam_controller"] = proc(sg: ^bang.SceneGraph) -> bang.Error {
    //     ball_t := bang.get_transform_by_name(sg, "player")
    //     if ball_t == nil {
    //         bang.error("failed to get player transform", .NilPtr)
    //     }
        

    //     return bang.good()
    // }
    
    // Action!
    bang.run_scene(window, &sg, FRAME_DURATION)
}



