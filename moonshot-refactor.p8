pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- globals
globals={
    -- general
    debug = true,

    -- physics
    grav = 0.05,
    friction = 0.425,

    -- sprite flags
    solid = 0,
    bullet = 6,
    actor = 7,

    -- star color pallet
    stars_color_pal={1,2,9,12,13}
}

-->8
-- main
function _init()
    p = player:new(10, 20)
    -- TODO dont fall off edge
    m = gmap:new(0, 256)
    b = background:new(m)
    c = cam:new(m.map_start, m.map_end)

    bad_1 = baddie:new(60, 60, 17)
    add(baddies,bad_1)

end

function _update60()
    bullets_update()
    baddies_update()
    p:update()
    c:update(p.x, p.w)
    m:update()
end

function _draw()
    cls()
    bullets_draw()
    baddies_draw()
    b:draw()
    m:draw()
    p:draw()

    if (globals.debug) draw_debug()
end

-->8
-- environments

-- draw_debug assumes player p
function draw_debug()
    local y = 2
    local i = 7 
    local x_offset = 5
    print("player_state: "..p.state, c.x + x_offset, y)
    print("player_dx: "..p.dx, c.x + x_offset, y + 1 * i)
    print("player_dy: "..p.dy, c.x + x_offset, y + 2 * i)
    print("player_x: "..p.x, c.x + x_offset, y + 3 * i)
    print("cam_x: "..c.x, c.x + x_offset, y + 4 * i)
    print("map_start: "..c.map_start, c.x + x_offset, y + 5 * i)
    print("debug_var: "..p.debug_var, c.x + x_offset, y + 6 * i)
end

-->8
-- background

background = {}

function background:new(m)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.stars = self:stars_init(m)
    return o 
end

function background:draw()
    self:stars_draw()
end

-- stars
-- m: map object
-- perc: percentage of stars for the creen
-- todo: handle different screen hights
function background:stars_init(m, perc)

  local perc = perc or 0.05
  local stars={}
  local num = (128 * perc) * (m.map_end * perc)
  
  for i=1,num do
    s={}
    s.x=rnd(m.map_end)
    s.y=rnd(128)
    s.color=globals.stars_color_pal[
        flr(rnd(count(globals.stars_color_pal)))+1]
    s.size=rnd(2)
    add(stars, s)
  end

  return stars
end

function background:stars_draw()
    for s in all(self.stars) do
        circfill(flr(s.x),s.y,s.size,s.color)
    end
end


-->8
--gmap
gmap = {}

-- gmap:new
-- create a new game map
-- map_start: start position of map
-- map_end: end position of map
function gmap:new(map_start, map_end)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.map_start = map_start
    o.map_end = map_end
    return o 
end


-- gmap reset
function gmap:reset(map_start, map_end)
    c.map_start = map_start
    c.map_end = map_end
end

-- update map
function gmap:update()
end

-- todo fix this
function gmap:draw()
    map(0, 0)
end

function actor_collision(actor_a, acotr_b)
end

-->8
-- actors

-- actor_map_collision
-- check if there is a collision between an object and a sprite
-- actor: table x,y,w,h 
-- direction with left,right,up,down as options
-- flag: sprite flag type
-- returns: bool
function actor_map_collision(actor, direction, flag)

    local x=actor.x  local y=actor.y
    local w=actor.w  local h=actor.h
  
    local x1=0  local y1=0
    local x2=0  local y2=0
  
    if direction == "left" then
        x1 = x - 1 
        y1 = y
        x2 = x
        y2 = y + h - 1
        
    elseif direction == "right" then
        x1 = x + w - 1
        y1 = y
        x2 = x + w
        y2 = y + h - 1
        
    elseif direction == "up" then
        x1 = x + 2
        y1 = y - 1
        x2 = x + w - 3
        y2 = y
        
    elseif direction == "down" then
        x1 = x + 2
        y1 = y + h
        x2 = x + w - 3
        y2 = y + h
    end
    -- sprites are 8 pixels
    x1 /= 8
    y1 /= 8
    x2 /= 8
    y2 /= 8
  
    if fget(mget(x1,y1),flag) 
    or fget(mget(x1,y2),flag) 
    or fget(mget(x2,y1),flag) 
    or fget(mget(x2,y2),flag) then
        return true
    end
    
    return false 

end

function actor_move(actor)
    -- check y direction
    if actor.dy > 0 then
        actor.state = "falling"

        -- limit actor to max speed
        actor.dy = mid(-actor.dy, actor.dy, actor.max_dy)

        if actor_map_collision(actor, "down", globals.solid) then
            actor.grounded = true
            -- left/right movement
            if btn(0)
            or btn(1) then
                actor.state = "running"
            else
                actor.state = "idle"
            end
            actor.dy = 0
            actor.y -= ((actor.y + actor.h + 1) % 8) - 1
        end
    elseif actor.dy < 0 then
        actor.state = "jumping"
        if actor_map_collision(actor, "up", globals.solid) then
            actor.dy = 0
        end
    end

    -- check x direction
    -- left movement
    if actor.dx < 0 then
        -- limit actor to max speed
        actor.dx = mid(-actor.max_dx, actor.dx, actor.max_dx)
        if actor_map_collision(actor, "left", globals.solid) then
            actor.dx = 0
        end
    -- right movement
    elseif actor.dx > 0 then
        actor.dx = mid(-actor.max_dx, actor.dx, actor.max_dx)
        if actor_map_collision(actor, "right", globals.solid) then
            actor.dx = 0
        end
    end

    actor.x += actor.dx
    actor.y += actor.dy

    --limit to map
    if actor.x < m.map_start then
        actor.x = m.map_start
    end
    if actor.x > m.map_end - actor.w then
        actor.x = m.map_end - actor.w
    end 


end

-- actor direction determines if actor is moving left or right
-- returns 1 if moving right, and returns -1 if moving left
-- assumes sprite is facing right and actor has var flip 
function actor_direction(flip)
    if (flip) return -1
    return 1
end

-->8
-- player

player={}

function player:new(x,y)
    local o={}
    setmetatable(o, self)
    self.__index = self
    -- sprite
    o.sp = 2
    -- state
    o.state = "falling"
    -- sprite x position
    o.x = x
    -- sprite y position
    o.y = y
    -- animation timing
    o.anim = 0
    -- flip sprit horizontal
    o.flip = false
    -- sprite width/height in pixels
    o.w = 8
    o.h = 8
    -- player x speed
    o.dx = 0
    o.max_dx = 1.5
    o.acc_x = 0.30
    -- player y speed
    o.dy = 0
    o.max_dy = 1.5
    o.acc_y = 2
    -- jumping
    o.jump_press = 0
    o.jump_press_time = 0.2
    o.grounded_press = 0
    o.grounded_press_time = 0.25
    o.grounded = false
    o.debug_var = "test"
    -- player health and lives
    o.health = 1
    o.lives = 3
    -- player hitbox
    hitbox = {
        x=0,
    }

    return o
end

-- TODO -
function player:draw_lives()
end

function player:animate()
  if self.state == "jumping" then
   self.sp = 6
  elseif self.state == "running" then
    if time() - self.anim > .1 then
      self.anim=time()
      self.sp += 1
      if self.sp > 5 then
        self.sp = 2
      end
    end
  else --player idle
      self.sp = 3
  end
end

function player:move_left()
    self.dx -= self.acc_x
    self.flip = true
end

function player:move_right()
    self.dx += self.acc_x
    self.flip = false
end

function player:jump()
    sfx(00)
    self.jump_press = 0
    self.grounded_press = 0
    self.grounded = false
    self.dy -= p.acc_y
end

function player:shoot()
    local b = bullet:new(self.x, self.y,
        self.flip)
    sfx(08)
    add(bullets, b)
end

function player:update()

    -- physics
    self.dy += globals.grav
    self.dx *= globals.friction

    if (btn(0)) self:move_left()
    if (btn(1)) self:move_right()

    -- shooting
    if (btnp(4)) self:shoot()

    -- jumping

    self.grounded_press -= 1/60
    if self.grounded then
        self.grounded_press = self.grounded_press_time
    end
    self.jump_press -= 1/60
    if btnp(5) then
        self.jump_press = self.jump_press_time
    end

    if self.jump_press > 0
    and self.grounded_press > 0 then
        self:jump()
    end


    actor_move(self)
end

-- draw player
function player:draw()
    self:animate()
    spr(self.sp, self.x, self.y, 1, 1, self.flip, false)
end

-->8
-- camera
cam={}

-- create a new camera, map_end is the end of the camera
function cam:new(map_start, map_end)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.x = 0
    o.map_start = map_start 
    o.map_end = map_end 
    return o 
end

-- update camera location give a players x position and the players width
function cam:update(player_x, player_w)
    -- camera follows player
    self.x = player_x - 64 + (player_w / 2)

    -- left end of camera doesnt move past start
    if (self.x < self.map_start) then
        self.x = self.map_start
    end

    -- end a gamescreen early from end
    if self.x > self.map_end - 128 then
        self.x = self.map_end - 128
    end

    camera(self.x, 0)

end

function cam:reset()
    camera()
end


-->8
-- bullets

-- array of all bullets
bullets={}
function bullets_update()
    for b in all(bullets) do
        b:update()

        local del_bullet = false

        if b.x < b.origin_x - b.distance 
        or b.x > b.origin_x + b.distance 
        or b.x < 0 then
            del_bullet = true
        end

        -- assumes sprite faces right
        local direction = "right"
        if (b.flip) direction = "left"
        collide_wall = actor_map_collision(b, direction, globals.solid)
        if collide_wall then
            del_bullet = true
        end

        if (del_bullet) del(bullets, b)

    end
end

function bullets_draw()
    for b in all(bullets) do
        b:draw()
    end
end

-- actual bullet obj
bullet={}

-- create a new bullets object
-- x: bullet spawn x
-- y: bullet spawn y
-- direction: string for left or right ("left", "right") 
function bullet:new(x, y, flip)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.sp = 32
    o.x = x
    o.y = y
    -- shot origin 
    o.origin_x = x
    o.origin_y = y
    --shot distance
    o.distance = 50
    o.w = 8
    o.h = 8
    o.dx = 1.5 * actor_direction(flip)
    o.dy = 0
    o.flip = flip
    return o 
end

function bullet:update()
    self.x += self.dx
    self.y += self.dy
end

function bullet:draw()
    spr(self.sp, self.x, self.y, 1, 1, self.flip, false)
end

-->8
-- egg

-- array of eggs
eggs = {}

egg = {}
-- create a new camera, map_end is the end of the camera
function egg:new(x, y)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.x = 0
    o.y = 0
    o.sp = 0
    return o 
end



-->8
-- baddie
baddie={}

-- baddie:new
-- x,y: where to start sprite
function baddie:new(x, y, sp)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.health = 3
    o.sp = sp 
    o.x = x
    o.y = y
    -- shot origin 
    o.origin_x = x
    o.origin_y = y
    --shot distance
    o.distance = 50
    o.w = 8
    o.h = 8
    o.dx = 0
    -- o.dx = 1.5 * actor_direction(flip)
    o.max_dx = 1
    o.dy = 0
    o.max_dy = 1.5
    o.flip = flip
    return o 
end


function baddie:update()
    self.dy += globals.grav
    actor_move(self)

    -- check if hit by bullet
    collide_actor = actor_map_collision(self, "down", globals.actor)
    if collide_actor then
        del(baddies, self)
    end

end

function baddie:draw()
    spr(self.sp, self.x, self.y, 1, 1, self.flip, false)
end


-->8
-- baddies
baddies={}

function baddies_update()
    for b in all(baddies) do
        b:update()
    end
end

function baddies_draw()
    for b in all(baddies) do
        b:draw()
    end
end


__gfx__
00000000000bbb0000000bb000000bb000000bb000000bb00000bb00000000000000000000000000000000000000000000000000000000000000000000000000
00000000002bbcb00002bbcb0002bbcb0002bbcb0002bbcb002bbcb0000000000000000000000000000000000000000000000000000000000000000000000000
00700700000bbbb00000bbbb0000bbbb0000bbbb0000bbbb000bbbb0000000000000000000000000000000000000000000000000000000000000000000000000
00077000002bbb000002bbb00002bbb00002bbb00002bbb0002bbb00000000000000000000000000000000000000000000000000000000000000000000000000
00077000000bb0000b00bb000b00bb000b00bb000b00bb00000bb000000000000000000000000000000000000000000000000000000000000000000000000000
007007000b0bbb0000bbbbb000bbbbb000bbbbb000bbbbb0000bbb00000000000000000000000000000000000000000000000000000000000000000000000000
0000000000bbb000000bb000000bb000000bb000000b330000bbb0b0000000000000000000000000000000000000000000000000000000000000000000000000
000000000003bb000003bb000030bb00000bb30000b003300b000b00000000000000000000000000000000000000000000000000000000000000000000000000
0000000000111d0000111d0000111d0000111d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000ed000011aa9d0011aa9d0011aa9d0011aa9d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00deee00011a99d0011a99d0011a99d0011a99d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0ddeedd0011999d0011999d0011999d0011999d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0eeeeed0061ddd00061ddd00061ddd00061ddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0eedeee0066655550666555506665555066655550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0deddee00015dd000015dd000015dd000015dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00deee00000d0100000d100000010d000001d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000a98000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000998000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000a98000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00dddd0000dddddddddddddddddddddddddddddddddddd0000000000000000000000000000000000000000000000000000000000dddddddddddddddddddddddd
0dddddd00ddddddddd55d5ddddddddddddddddddddddddd000000000000000000000000000000000000000000000000000000000177777777777777777777771
ddddddddddddddd5ddd5565dd5ddd5dd55dddddddddddddd00000000000000000000000000000000000000000000000000000000166666666666666666666661
ddddddddddd5dd5655d56665565dd6d55ddd5dd5dddddddd00000000000000000000000000000000000000000000000000000000166666666666666666666661
5dd5d55ddd565de6665666d6666556566dd555d65ddd5ddd00000000000000000000000000000000000000000000000000000000111111111111111111111111
6dd65c5dd56665666266655d6626666665d66656cd5d6d5d00000000000000000000000000000000000000000000000000000000000000000000000000000000
6556665556e6626666666655566655666c56e6666d256d6500000000000000000000000000000000000000000000000000000000000000000000000000000000
666e66660666666c6e666666666e66c666666666d566e66000000000000000000000000000000000000000000000000000000000000000000000000000000000
666666660666666666666666666666666666666c6666666000000000000000000000000000000000000000000000000000000000000000000000000000000000
62666c660c66e66626666e666666676662666666e6666e6000000000000000000000000000000000000000000000000000000000000000000000000000000000
6666666606666666666666266c6667766666c666666d666000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666e66066d66e6665566666667766666666d566666666000000000000000000000000000000000000000000000000000000000000000000000000000000000
666d66660266666665666c66666676e65666d5666666666000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666066666c666666666626666655d6e6666666c666000000000000000000000000000000000000000000000000000000000000000000000000000000000
6e6666c606e6666666e666c66666e6665d6662666d66666000000000000000000000000000000000000000000000000000000000000000000000000000000000
6666666606666d66666666666666666c6666666666666e6000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddd6666266ddddddddd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d66666616e6666dddddddddd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d66666616666e6dddddddddd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d6666661666666d55ddd5dd500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d666666126c6665665d5dd5600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d66666616666666666d6d56600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d66666616e666e6666566c6600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d1111111666666c66e6666c600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000060000000000000006000005000600000000050000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04000005000000000000000500000000000600000000000400000000000000060000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00050000000400000004000000000400040000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000006000000000000000006000000000000060000000000000004000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00040000000005000000000000000004000000000000000000000000050000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000060000000000040000060000000005000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000004000005000000000000000000000000000000040000040000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00060000000000000400000400050000050000000000000000000000000500000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000005000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06000000000500000005000000000000000006060004000006000000000000060000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000004000000000006000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00050006000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000040000060000000000040000040000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000004000005000000000000000005000600000000000000000500000400000000000000577747270000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00040000000000000000000000000000000000000000000000000000000000000000000007171717176700000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000005717171717171727000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000600050000000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000002000000000660565000000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000022000000000606650000000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000228000000000006660000044440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00002288000000000000600000040040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00022888000000000006560000040040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00228888000000000060506000040040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00888888000000000600500600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00008888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000588000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001151000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010551000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100551000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0080808080808000000000000000000000fefefefe0000000000000000000000400000000000000000000000000000000000000000000000000000000000000001010101010101010000000000000002010101010101000000000000000000000101010100000000000000000000000001000000000000000000000000000001
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000414500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000606060000000000000600000600000515500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000600000600000516162450000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6244424362436242444262446244424362446243446244624342444362424344000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5050505050505050505050505050505050505050505250545050505050505050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000201000302006020090200b0100d010110501405004000030000300003000030000200002000010000000001000020000100001000010000100000000000000100002000020000200002000010000100001000
013000202773427724227341d734187241b74422724247441b74422724247341f724247342773429724247342773427724227241d734187241b73422724247241f7342272424724277241f734277342972426734
011800200004003040000400704107040070100701000000000400304000040070410704007010070100000000040030400004008041080400801008010000000004003040000400804108040080100c04007010
011800200c0430c0430c0433f003246150000000000246150c05300000000000c0530c0530c01324600246150c0430c0230c0530c0432461500000000000c04300000000000c043180330c043180002461524615
01300000135221352213522135221351213532135321353218532185221852218512185121851218512185122b5222e52233522335223352224532185421654218542185521b5521d5521f542225422453227522
0118002000043000430304300003076150300003000006150c05300000000000c0530c0530c01324600246150c0430c0230c0530c0432461300000000000c04000000000000c040180300c040180002461024610
00300010050300a0300c0400c0300c0400c0400a03007040050300503005020050300a0400a040050300304000000050500c0400c0300c0400c0400a03007040050500505005050050500a0500a0500505003050
001800200f7301373116730187301b7301d7301b7301b7301873018730187301b7301f7301d73022730227301f7301f7301f7301b7301d73022730227301f7301f7301d7301d7301b7301b730167301873018730
000600000264012640066400463009620056100060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
000100002903024030210301f0201c0201b0301903018020160301503014030130201202011020100300f0300c0300a0400904009040080300703007030060200502004020030300304004040020400104011030
__music__
01 02010344
01 06070344
00 02010344