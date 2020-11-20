pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- main
-- contains pico-8 main functions

function _init()
    p = player:new()
    c = cam:new()
    g = game:new()
    m = gmap:new()
    g:init()
end

function _update60()
    g:update()
end

function _draw()
    cls()
    g:draw()
end

-->8
-- globals
-- contains any globally used defintions outside of objects
-- that have their own tab.

globals = {

    -- application
    title = "moonshot",
    version = "0.0.0",

    -- debugging 
    debug = true,
    -- gengeral purpose debug variable
    debug_var = "",
    -- vector2d
    debug_position = "",
    debug_vel = "",

    -- stars 
    stars_color_pal={1,2,9,12,13},

    -- physics
    grav = 0.05,
    friction = 0.425,

    -- sprite flags
    solid = 0,
    spike = 5,
    bullet = 6

}

-->8
-- game
game = {}

-- initalize game object
function game:new()
    local o={}
    setmetatable(o, self)
    self.__index = self
    -- state: a table with new/init/update/draw functions
    o.state = nil
    return o
end

-- game:init
-- Calling this function will start the game over at menu screen
-- start with menu state
function game:init()
    self:change_state(menu)
end

function game:update()
    self.state:update()
end

function game:draw()
    -- cls()
    self.state:draw()

    if globals.debug then

        local x = c.x or 0

        -- debug var
        print("debug var: " .. globals.debug_var, x, 0, 9)

        -- user input
        local key = ""
        if (btn(0)) key = key .. "left "
        if (btn(1)) key = key .. "right "
        if (btn(2)) key = key .. "up "
        if (btn(3)) key = key .. "down "
        if (btn(4)) key = key .. "x "
        if (btn(5)) key = key .. "o "
        -- print("user input: " .. key, x, 7, 9)
        -- print("position: " .. globals.debug_position, x, 14, 9)
        -- print("velocity: " .. globals.debug_vel, x, 21, 9)

    end

end

-- game:change_state
-- change to a new state
-- takes in a table with new/init/update/draw functions
function game:change_state(state)
    self.state = state:new()
    self.state:init()
end


-->8
-- menu
menu = {}

function menu:new()
    local o={}
    setmetatable(o, self)
    self.__index = self
    -- background object
    o.background = background:new()
    return o
end

-- menu:init
-- reset menu screen
function menu:init()
    -- map is just blank screen
    m:init(0, 128)
    c:init(m.map_start, m.map_end)
    self.background:init(self.map)
    music(0)
end

-- menu:update
-- check if player wants to start
function  menu:update()
    c:update(0, 0)
    if btnp(4) then
        -- start playing level 1
        g:change_state(levelmanager)
    end
end

-- menu:draw
-- draw menu screen
function  menu:draw()
    self.background:draw()
    print("press ❎", 50, 80, 7)
    print("deejay paredi", 41, 100, 5)
    print("patrick messina", 37, 106, 5)
    print("bard development", 0, 120, 5)
    print(globals.version, 109, 120, 5)
end

-->8
-- game over 
game_over = {}

function game_over:new()
    local o={}
    setmetatable(o, self)
    self.__index = self
    -- background object
    o.background = background:new()
    return o
end

-- game_over:init
-- reset game_over screen
function game_over:init(win)
    self.win = win or false
    -- map is just blank screen
    m:init(0, 128)
    self.background:init(self.map)
    music(0)
end

-- game_over:update
-- check if player wants to start
function  game_over:update()
    c:update(0, 0)
    if btnp(4) then
        -- start playing level 1
        g:change_state(menu)
    end
end

-- game_over:draw
function  game_over:draw()
    self.background:draw()
    if p.lives > 0 then
        print("you win!", 60, 60)
    else
        print("you lose, loser.", 60, 60)
    end
    print("press ❎", 50, 80, 7)
end




-->8
-- gmap
-- game map
gmap = {}

-- gmap:new
-- create a new game map
function gmap:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    -- integer for map start and end
    o.map_start = nil
    o.map_end = nil
    -- upper left corner column of region to draw
    o.x = nil
    -- upper left corner row of region to draw
    o.y = nil
    return o 
end

function gmap:init(map_start, map_end, map_x, map_y)
    local map_x = map_x or nil
    local map_y = map_x or nil
    self.map_start = map_start
    self.map_end = map_end
    if map_x ~= nil
    and map_y ~= nil then
        self.x = map_x
        self.y = map_y
    end
end

-- update map
function gmap:update()
end

function gmap:draw()
    if map_x ~= nil
    and map_y ~= nil then
        map(self.x, self.y)
    end
end

-->8
-- background
-- handle background elements
-- stars draws stars randomly placed

background = {}

-- background:new
-- create a new background object
function background:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    -- array of stars
    o.stars = nil
    return o 
end

-- background:init
-- m: map object
-- s: stars bool, default is true
-- sperc: percentage of stars for the map default 5%
function background:init(stars, sperc)

    local stars = stars or true
    local sperc = sperc or 0.05

    if stars then
        self.stars = self:stars_init(sperc)
    end

end

-- stars
-- m: map object
-- perc: percentage of stars for the creen
-- todo: handle different screen hights
function background:stars_init(perc)

  local perc = perc or 0.05
  local stars={}
  local num = (128 * perc) * (m.map_end * perc)
  
  for i=1,num do
    s={}
    s.x=rnd(m.map_end)
    s.y=rnd(128)
    s.color=globals.stars_color_pal[
        flr(rnd(count(globals.stars_color_pal)))+1]
    s.size=flr(rnd(2))
    add(stars, s)
  end

  return stars
end

function background:stars_draw()
    for s in all(self.stars) do
        local x = flr(s.x)
        local y = flr(s.y)
        rectfill(x, y, x+s.size, y+s.size, s.color)
    end
end

function background:update()
end

function background:draw()
    self:stars_draw()
end

-->8
-- levelmanager
levelmanager = {}
function levelmanager:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    -- array of levels
    o.levels = nil
    -- level index
    o.index = nil
    return o 
end

function levelmanager:init()

    self.levels = {}
    self.index = 1


    -- create level 1

    m:init(0, 1024, 0, 0)
    local level_1 = level:new()
    local b = background:new()
    b:init()

    -- reset player
    p:init(20, 20)

    -- set camera
    c:init(m.map_start, m.map_end)

    -- pos, sp, hitbox, health, bullet_sp, bullet_distance, bullet_max_time, acc
    local level_baddies = {
        baddie:new(vector2d(70, 70), 17, new_hitbox(0,0,7,7), 3, 0, 50, 30, vector2d(1.5, 0))
    }

    level_1:init(m, b, level_baddies)
    add(self.levels, level_1)

end

function levelmanager:update()
    local i = self.index
    self.levels[i]:update()
    baddies_update(self.levels[i].baddies)
    p:update()
    bullets_update()
    particle_update()
    c:update(p.pos.x, p.w)
end

function levelmanager:draw()
    local i = self.index
    self.levels[i]:draw()
    baddies_draw(self.levels[i].baddies)
    bullets_draw()
    particle_draw()
    p:draw()
end

-->8
-- level

level={}
function level:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    -- gmap object
    o.map = nil
    -- background object
    o.background = nil
    return o 
end

function level:init(m, b, badguys)
    self.background = b
    self.baddies = badguys
    -- music(1)
end

function level:update()
end

function level:draw()
    self.background:draw()
    map(self.map_x, self.max_y)
end

-->8
-- actor

-- actor direction determines if actor is moving left or right
-- actor direction determines if actor is moving left or right
-- returns 1 if moving right, and returns -1 if moving left
-- assumes sprite is facing right and actor has var flip 
function actor_direction(flip)
    if (flip) return -1
    return 1
end

-- actor_move
-- moves actor on screen and checks for collisions
-- actor requires
--  state: with falling/running/jumping/idle
--  position: vector2d
--  vel: vector2d
function actor_move(actor)
    -- check y direction
    if actor.vel.y > 0 then
        actor.state = "falling"

        -- if player falls off the map
        if actor.pos.y > m.y + 128 then
            actor.health -= actor.health
            return
        end

        -- limit actor to max speed
        actor.vel.y = mid(-actor.max_vel.y, actor.vel.y, actor.max_vel.y)

        if actor_map_collision(actor, "down", globals.solid) then
            actor.grounded = true

            -- left/right movement
            if btn(0)
            or btn(1) then
                actor.state = "running"
            else
                actor.state = "idle"
            end
            actor.vel.y = 0
            actor.pos.y -= ((actor.pos.y + actor.h + 1) % 8) - 1
        end

        if actor_map_collision(actor, "down", globals.spike) then
            actor.vel.y = 0
            actor.health -= actor.health
        end

    elseif actor.vel.y < 0 then
        actor.state = "jumping"
        if actor_map_collision(actor, "up", globals.solid) then
            actor.vel.y = 0
        end
    end

    -- check x direction
    -- left movement
    if actor.vel.x < 0 then
        -- limit actor to max speed
        actor.vel.x = mid(-actor.max_vel.x, actor.vel.x, actor.max_vel.x)
        if actor_map_collision(actor, "left", globals.solid) then
            actor.vel.x = 0
        end
    -- right movement
    elseif actor.vel.x > 0 then
        actor.vel.x = mid(-actor.max_vel.x, actor.vel.x, actor.max_vel.x)
        if actor_map_collision(actor, "right", globals.solid) then
            actor.vel.x = 0
        end
    end

    actor.pos += actor.vel

    --limit to map
    if actor.pos.x < m.map_start then
        actor.pos.x = m.map_start
    end
    if actor.pos.x > m.map_end - actor.w then
        actor.pos.x = m.map_end - actor.w
    end 


end


-->8
-- baddie

function baddies_update(baddies)
    for b in all(baddies) do
        b:update()
        if b.health <= 0 then
        particle_death(b.pos)
            particle_death(b.pos)
            del(baddies, b)
        end
    end
end

function baddies_draw(baddies)
    for b in all(baddies) do
        b:draw()
    end
end



baddie = {}

-- baddie:new
-- initalize an enemy
-- sp: sprite number of enemy
-- pos: vector2d start position 
-- hitbox: hitbox table
-- health: starting health
-- bullet_sp: sprite number for bullet
-- acc: acceleration vector2d
function baddie:new(pos, sp, hitbox, health, bullet_sp, bullet_distance, bullet_max_time, acc)
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.sp = sp
    o.bullet_sp = bullet_sp
    o.bullet_distance = bullet_distance
    o.bullet_timer = 0
    o.bullet_max_time = bullet_max_time
    o.bullet_hitbox = new_hitbox(5,2,3,3)
    o.hitbox = hitbox
    o.w = 8
    o.h = 8
    o.pos = pos
    o.health = health
    o.flip = true

    o.vel = vector2d(0, 0)
    o.max_vel = vector2d(2, 2)

    o.acc = acc

    return o 
end

function baddie:update()
    -- TODO see why this is so slow
    self.vel.y += globals.grav
    self.vel.x *= globals.friction

    actor_move(self)

    collide_actor = actor_map_collision(self, "down", globals.actor)


    self:shoot()

    -- check if hit by bullet
    for b in all(bullets) do
        if actor_collision(b, self) then
            self.health -= 1
            del(bullets, b)
        end
    end

end

function baddie:draw()
    spr(self.sp, self.pos.x, self.pos.y, 1, 1, self.flip, false)
    if globals.debug then 
        draw_hitbox(self.pos, self.hitbox, 9)
        actor_collision_draw()
    end
end

-- badie shoot
function baddie:shoot()

    -- globals.debug_var = self.hitbox
    if self.bullet_timer <= self.bullet_max_time then
        self.bullet_timer += 1
        return
    end
    self.bullet_timer = 0

    local dir = actor_direction(self)
    -- if facing right
    if dir == 1 then
    -- if facing left
    else
        local p_x = p.pos.x + p.hitbox.x + p.hitbox.w + 1
        local p_y = p.pos.y + p.hitbox.y + p.hitbox.h + 1
        if p_x > self.pos.x - self.bullet_distance
        and p_x - p.hitbox.x <= self.pos.x
        and p_y > self.pos.y +  self.hitbox.h
        then
            -- TODO im tired, double check this
            local dir = actor_direction(self)
            local b_pos = vector2d() 
            -- facing right
            if actor_direction(self) == 1 then
                b_pos = vector2d(self.pos.x + self.hitbox.x + self.hitbox.w + self.bullet_hitbox.x,
                                 self.pos.y + 1)
            -- facing left
            else
                local _box = hitbox_position(self.hitbox, actor_direction(flip))
                local _b_box = hitbox_position(self.bullet_hitbox, actor_direction(flip))
                -- b_pos = vector2d(self.pos.x - 4 - _b_box.x - _b_box.w,
                b_pos = vector2d(self.pos.x - 10,
                                 self.pos.y + 0)
                -- b_pos = vector2d(self.pos.x - (self.bullet_hitbox.w + self.bullet_hitbox.x), self.pos.y)
            end
            local b = bullet:new(b_pos , 32, self.bullet_hitbox, 50, self.flip)
            add(bullets, b)
        end
    end
end


-- actor_collision
-- check collision between two actors
-- requires a hitbox
-- a: actor 1
-- b: actor 2
-- returns true if collision, false otherwise
a = {x=0,y=0,w=0,h=0}
b = {x=0,y=0,w=0,h=0}
function actor_collision(actor_a, actor_b)
    a = {x=0,y=0,w=0,h=0}
    b = {x=0,y=0,w=0,h=0}

    -- local a = actor_1.hitbox
    -- local b = actor_2.hitbox

    local dir_a = actor_direction(actor_a)
    local dir_b = actor_direction(actor_b)


    -- position hitbox for actor a
    -- facing right
    if dir_a == 1 then
        a = new_hitbox(actor_a.pos.x + actor_a.hitbox.x,
            actor_a.pos.y + actor_a.hitbox.y, 
            actor_a.hitbox.w, actor_a.hitbox.h)
    else
        local _a = hitbox_position(actor_a.hitbox, dir_b)
        a = new_hitbox(actor_a.pos.x + _a.x,
            actor_a.pos.y + _a.y, _a.w, _a.h)
    end
    -- position hitbox for actor b
    if dir_b == 1 then
        b = new_hitbox(actor_b.pos.x + actor_b.hitbox.x,
            actor_b.pos.y + actor_b.hitbox.y, 
            actor_b.hitbox.w, actor_b.hitbox.h)
    else
        local _b = hitbox_position(actor_b.hitbox, dir_b)
        b = new_hitbox(actor_b.pos.x + _b.x,
            actor_b.pos.y + _b.y, _b.w, _b.h)
    end

    if a.x < b.x + b.w
    and a.x + a.w > b.x
    and a.y < b.y + b.h
    and a.y + a.h > b.y then
        return true
    end
    return false
end

function actor_collision_draw()
    local x1 = a.x
    local x2 = a.x + a.w
    local y1 = a.y
    local y2 = a.y + a.h
    rect(x1, y1, x2, y2, 3)
    local x1 = b.x
    local x2 = b.x + b.w
    local y1 = b.y
    local y2 = b.y + b.h
    rect(x1, y1, x2, y2, 3)
end


-- actor_map_collision
-- check if there is a collision between an object and a sprite
-- actor: table x,y,w,h 
-- direction with left,right,up,down as options
-- flag: sprite flag type
-- returns: bool
function actor_map_collision(actor, direction, flag)

    local x=actor.pos.x  local y=actor.pos.y
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


-->8
-- player

player={}

function player:new()
    local o={}
    setmetatable(o, self)
    self.__index = self
    -- sprite number
    o.sp = 2
    -- width/height of sprite
    o.w = 8
    o.h = 8
    self.vel = vector2d(0, 0)

    return o
end

-- player:init
-- player start position x,y
-- m gmap object
function player:init(x, y)

    -- sprite number
    self.sp = 2
    self.w = 8
    self.h = 8
    self.flip = false
    self.anim = 0

    -- state
    -- falling/running/jumping/idle
    self.state = "falling"

    -- health stuff
    self.health = 1
    self.lives = 3

    self.hitbox = {
        x = 1,
        y = 0,
        w = 6,
        h = 7
    }
    -- movement
    self.pos = vector2d(x, y)

    self.vel = vector2d(0, 0)
    self.max_vel = vector2d(2, 2)

    self.acc = vector2d(0.5, 2.2)
    self.dcc = vector2d(0.8, 0)
    self.dcc_air = vector2d(1.5, 0)

    -- jumping
    self.jump_hold = globals.grav

    -- check if almost touch ground
    self.jump_press = 0
    self.jump_press_time = 0.2

    self.grounded_press = 0
    self.grounded_press_time = 0.25
    self.grounded = false

  
end

function player:draw_lives()
    spr(48, c.x + 110)
    print("x" .. self.lives, c.x + 120, 0, 9)
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

function player:jump()
    sfx(00)
    self.jump_press = 0
    self.grounded_press = 0
    self.grounded = false

    self.vel.y -= p.acc.y 
end

function player:death()
    self.lives -= 1
    self.health = 1
    if self.lives <= 0 then
        g:change_state(game_over)
    else
        -- TODO this needs adjusting
        p.pos = vector2d(20, 20)
    end
end

function player:shoot()

    -- todo make bullet distance a value in init
    local b = bullet:new(self.pos, 32, new_hitbox(5,2,3,3), 50, self.flip)
    sfx(10)
    add(bullets, b)
end

function player:update()

    globals.debug_position = self.pos

    self.vel.x *= globals.friction 
    self.vel.y += globals.grav + self.jump_hold

    -- shooting
    if (btnp(4)) self:shoot()

    -- left
    if btn(0) then
        self.vel.x -= self.acc.x
        self.flip = true
    -- right
    elseif btn(1) then
        self.vel.x += self.acc.x
        self.flip = false
    -- allow a minor delay before changing directions/stopping
    else
        if self.grounded then
            self.vel.x *= self.dcc.x
        else
            self.vel.x *= self.dcc_air.x
        end
    end

    
    -- jumping
    self.grounded_press -= 1/60
    if self.grounded then
        self.grounded_press = self.grounded_press_time
    end
    self.jump_press -= 1/60

    if btnp(5) then
        self.jump_press = self.jump_press_time
    end
    -- h check for how long jump is press
    if btn(5) then
        self.jump_hold -= 0.005
        if (self.jump_hold < 0) self.jump_hold = 0
    else
        self.jump_hold = globals.grav
    end

    if self.jump_press > 0
    and self.grounded_press > 0 then
        self:jump()
    end

    globals.debug_vel = self.vel
    actor_move(self)

    if self.health <= 0 then
        self:death()
    end

end

function player:draw()
    self:draw_lives()
    self:animate()
    spr(self.sp, self.pos.x, self.pos.y, 1, 1, self.flip, false)
    if globals.debug then 
        draw_hitbox(self.pos, self.hitbox, 2)
    end
end


-->8
-- actors

-->8
-- camera
cam={}

-- create a new camera, map_end is the end of the camera
function cam:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.x = nil 
    o.map_start = nil
    o.map_end = nil 
    return o 
end

function cam:init(map_start, map_end)
    self.x = 0 
    self.map_start = map_start
    self.map_end = map_end 
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

        if b.pos.x < b.origin.x - b.distance 
        or b.pos.x > b.origin.x + b.distance 
        or b.pos.x < 0 then
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

        if globals.debug then 
            draw_hitbox(b.pos, b.hitbox, 7)
        end

    end
end

-- actual bullet obj
bullet={}

-- create a new bullets object
-- pos: position vector
-- direction: string for left or right ("left", "right") 
function bullet:new(pos, sp, hitbox, distance, flip)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.sp = 32
    o.pos = pos
    -- shot origin 
    o.origin = pos
    --shot distance
    o.distance = distance
    self.hitbox = hitbox_position(hitbox, actor_direction(flip))

    -- used for map collision
    o.w = 8
    o.h = 8

    o.vel = vector2d(1.5 * actor_direction(flip), 0)
    o.flip = flip
    return o 
end


function bullet:update()
    self.pos += self.vel
end

function bullet:draw()
    spr(self.sp, self.pos.x, self.pos.y, 1, 1, self.flip, false)
end


-->8
-- particles
particles = {}

-- add particles
-- pos: position of particle vector2d
-- t: type
-- color: array of colors
-- max_age: how long the particle should live
particle={}
function particle:new(pos, t, color, max_age)

    local old_color = old_color or color

    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.pos = pos
    o.type = t
    o.color = color
    o.old_color = old_color
    o.age = 0
    o.max_age = max_age

    return o
end

function particle_update()
    for part in all(particles) do
        -- make sure particles are not too old
        part.age += 1

        -- change color when its old
        if part.age / part.max_age > 0.5 then
            part.color = part.old_color
        end

        if part.age > part.max_age then
            del(particles, part)
        end
    end
end

function particle_draw()
    for part in all(particles) do
        -- 1 pixel particle
        if part.type == 0 then
            pset(part.pos.x, part.pos.y, part.color[1])
        end
    end
end

-- create new death particle effect
function particle_death(pos)
    local part = particle:new(pos, 0, {8}, 15+rnd(2))
    add(particles, part)
end


-->8
-- utils

-- draw hitbox
-- pos: position vector
-- h: hitbox
-- c: color (int)
function draw_hitbox(pos, h, c)
    local x1 = pos.x + h.x 
    local x2 = pos.x + h.x + h.w
    local y1 = pos.y + h.y
    local y2 = pos.y + h.y + h.h
    rect(x1, y1, x2, y2, c)
end

-- vector
-- vector in R2
vector = {}
function vector2d(x, y)

    local v = {}
    setmetatable(v, vector)
    v.x = x or 0
    v.y = y or 0
    return v 
end

-- vector:length
-- returns length of vector
function vector:length(a)
    return sqrt(a.x^2 + a.y^2)
end

-- vector:normalize
function vector:normalize(a)
    local m = vector:length(a)
    if (m == 0) return vector2d(0, 0)
    local x = a.x / m
    local y = a.y / m
    return vector2d(x, y)
end

-- scaler or dot product
function vector.__mul(a, b)
    if type(a) == "number" then
        return vector2d(a * b.x, a * b.y)
    elseif type(b) == "number" then
        return vector2d(a.x * b, a.y * b)
    end
    return a.x * b.x + a.y * b.y
end

function vector.__add(a, b)
    return vector2d(a.x + b.x, a.y + b.y)
end

function vector.__sub(a, b)
    return vector2d(a.x - b.x, a.y - b.y)
end

function vector.__eq(a, b)
    return a.x == b.x and a.y == b.y
end

function vector.__tostring(a)
    return "(".. a.x .. ", " .. a.y .. ")"
end

function vector.__concat(s, t) 
    return tostring(s) .. tostring(t)
end

-- hitbox
hitbox = {}
function new_hitbox(_x, _y, _w, _h)

    local o = {}
    setmetatable(o, hitbox)
    o.x = _x or 0
    o.y = _y or 0
    o.w = _w or 8
    o.h = _h or 8
    return o 

end

-- determine the location of a hitbox
-- returns a position hitbox
-- actor: actor who has a hitbox and flip
-- {x,y,w,h}
function hitbox_position(b, dir)

    local h = {}
    h.w = b.w
    h.h = b.h
    -- facing right
    if dir == 1 then
        h.x = b.x
        h.y = b.y
    -- facing left
    else
        h.x = 7 - (b.w + b.x) 
        h.y = 7 - (b.h + b.y) 
    end
    return h
end

function hitbox.__tostring(s)
    return "{x: " .. s.x .. ", y: " .. s.y .. ",\n w: " .. s.w .. ", h: " .. s.h .. "}"
end

function hitbox.__concat(s, t) 
    return tostring(s) .. tostring(t)
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
00e80880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00088800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00dddd0000dddddddddddddddddddddddddddddddddddd00666666666666d6660000000000000000000000000000000000000000dddddddddddddddddddddddd
0dddddd00ddddddddd55d5ddddddddddddddddddddddddd06d666666667766660000000000000000000000000000000000000000177777777777777777777771
ddddddddddddddd5ddd5565dd5ddd5dd55dddddddddddddd66666666667766660000000000000000000000000000000000000000166666666666666666666661
ddddddddddd5dd5655d56665565dd6d55ddd5dd5dddddddd66666c66777776660000000000000000000000000000000000000000166666666666666666666661
5dd5d55ddd565de6665666d6666556566dd555d65ddd5ddd66d66677766776260000000000000000000000000000000000000000111111111111111111111111
6dd65c5dd56665666266655d6626666665d66656cd5d6d5d66777776666666660000000000000000000000000000000000000000000000000000000000000000
6556665556e6626666666655566655666c56e6666d256d6566777666666d66660000000000000000000000000000000000000000000000000000000000000000
666e66660666666c6e666666666e66c666666666d566e66066677e66666666660000000000000000000000000000000000000000000000000000000000000000
666666660666666666666666666666666666666c6666666066666666666666660000000055555500000000000000000000000000000000000000000000000000
62666c660c66e66626666e666666676662666666e6666e6066266666666c66660000000005555550000000000000000000000000000000000000000000000000
6666666606666666666666266c6667766666c666666d666066666666666666660000000000055550000000000000000000000000000000000000000000000000
66666e66066d66e6665566666667766666666d566666666066666666e66666660000000000005555000000000000000000000000000000000000000000000000
666d66660266666665666c66666676e65666d56666666660666666666666d6660000000000005555000000000000000000000000000000000000000000000000
66666666066666c666666666626666655d6e6666666c6660666c6666666666660000000000005555000000000000000000000000000000000000000000000000
6e6666c606e6666666e666c66666e6665d6662666d66666066666666662666660000055000005555000000000000000000000000000000000000000000000000
6666666606666d66666666666666666c6666666666666e6066666666666666660000555555555555000000000000000000000000000000000000000000000000
dddddddd6666266ddddddddd0000000000000000000000006666666666666666000055555555555500000000000000000000000000000000d000000000000000
177777716e6666dddddddddd0000000000000000000000006666666666666666000005500000555500000000000000000000000000000000d667700000000000
166666616666e6dddddddddd000000000000000000000000666d66666e66c666000000000000555500000000000000000000000000000000d666770000000000
16666661666666d55ddd5dd500000000000000000000000066666666666666d6000000000000555500000000000000000000000000000000d666700000000000
1666666126c6665665d5dd5600000000000000000000000066666c7777766666000000000005555500000000000000000000000000000000d000000000000000
166666616666666666d6d5660000000000000000000000006666667777776666000000000055555500000000000000000000000000000000d667700000000000
166666616e666e6666566c660000000000000000000000006666677766776666000000000555555000000000000000000000000000000000d666770000000000
11111111666666c66e6666c600000000000000000000000066d6676766776666000000005555550000000000000000000000000000000000d666700000000000
0000000000000000000000000000000000000000000000006666627677776666000000005111111111111111000000000000000000000000dddddddd00000000
000000000000000000000000000000000000000000000000666666777666c6660000000051111111111111110000000000000000000000000666066600000000
00000000000000000000000000000000000000000000000066666777766666660000000051111111111111110000000000000000000000000666066600700070
0000000000000000000000000000000000000000000000006666666666666d660000000051111111111111110000000000000000000000000766076607770777
000000000000000000000000000000000000000000000000666d6666666666660000000051111111111111110000000000000000000000000777077707660766
00000000000000000000000000000000000000000000000066666c66d66666660000000051111111111111110000000000000000000000000070007006660666
0000000000000000000000000000000000000000000000006e66666666666e660000000051111111111111110000000000000000000000000000000006660666
000000000000000000000000000000000000000000000000666666666666666600000000511111111111111100000000000000000000000000000000dddddddd
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
00000000000001150000000000000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000001150606666000000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000811150555555000000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000888000811150505555000555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000888000811150000100000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000778888811150001010000050500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000887777711150005050000050500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000778888818850050005000500050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000887777787750000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000778888878850000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000887777787750000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000008888878850000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000080050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0080808080808000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000001010101010100000000000000010101010101010101000000000000000000000101010100000000000000000000200001000000000000000000000000002020
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000797a
00000000000000000000000000000000000000000000000000000000000000007f7f7f00001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000041424242424242424242450000000000000000000000000000000000000000000000000000000000000000797a
000000000000000000000000000000000000000000000000000000414444444443434343434300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000051505050505050505050550000000000000000000000000000000000000000000060606000000000000000797a
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000051506667505050505050550000000000000000000000000000000000000000000000000000000000005859797a
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000515076775050505050505500000000000000000000000000007f7f00000000000000000000000000006869797a
000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000006060000000606000000000000000000000004d4e4f000000000000000000004d4e4f00000000505050505050464750550000000000000000000000000000606000000000000000000060606000000000797a
0000000000000000000000000000000000000000500000000000000000000000000000000000000000000000000060600000006060000000000000000000000000000000000000000000000000000000000000000050505050505657505500000000000000000000000060606060606000000000004b4c00000000000000797a
00000000000000000000000000000000110000005000001100000000000000000000000000000000110000000000606000000060607f7f000000000000000000000000000000004d4e4f000000000000000000000000505050505050505500000000000000000000001160606060606000000000005b5c00000000000000797a
6244424362436242444262446244424362446243446242434244444362424344434343434343434343434343444444450000004144444444444442424242450000000000000000000000000000000000000000000000505050505050506142424242424242424242424242424242424242424242424242424242424242424242
5050505050505050505050535050505050505050505253505050505050505050505050505050505050505050505050550000005150505050505050505050550000000000000000000000000000000000000000000000005050505050505050505050505050505050505050505050505050505050505050505050505050505050
__sfx__
000201000302006020090200b0100d010110501405004000030000300003000030000200002000010000000001000020000100001000010000100000000000000100002000020000200002000010000100001000
013000202773427724227341d734187241b74422724247441b74422724247341f724247342773429724247342773427724227241d734187241b73422724247241f7342272424724277241f734277342972426734
011800200004003040000400704107040070100701000000000400304000040070410704007010070100000000040030400004008041080400801008010000000004003040000400804108040080100c04007010
011800200c0430c0430c0433f003246150000000000246150c05300000000000c0530c0530c01324600246150c0430c0230c0530c0432461500000000000c04300000000000c043180330c043180002461524615
01300000135221352213522135221351213532135321353218532185221852218512185121851218512185122b5222e52233522335223352224532185421654218542185521b5521d5521f542225422453227522
0118002000043000430304300003076150300003000006150c05300000000000c0530c0530c01324600246150c0430c0230c0530c0432461300000000000c04000000000000c040180300c040180002461024610
01300010050300a0300c0400c0300c0400c0400a03007040050300503005020050300a0400a040050300304000000050300a0300c0400c0300c0400c0400a030070400500005000050000a0000a0000500003000
001800200f7301373116730187301b7301d7301b7301b7301873018730187301b7301f7301d73022730227301f7301f7301f7301b7301d73022730227301f7301f7301d7301d7301b7301b730167301873018730
000600000264012640066400463009620056100060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
000100002903024030210301f0201c0201b0301903018020160301503014030130201202011020100300f0300c0300a0400904009040080300703007030060200502004020030300304004040020400104011030
000400000b6300c6300d6300d6300e6300c6300a63009630086300761006610000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000200006300063030630000307625030000300000625005000006300063005000762503053005000050000063000630304300000076250300003000006250050000063000630050007625005000050000500
001000200a0100c0100c0100a01005010070100a0100c01011010130100f0100c0100c0100c0100f0101301016010130100f0100c0100f01011010130101601016010110100f010130100f010110100f0100f010
001000000077503705007050077500705007050077500705007050077500705007050077500705007750070500775037050070500775007050070500775007050070500775007050070503775007050077500705
011000000a0130c0130c0130a01305013070130a0130c01311013130130f0130c0130c0130c0130f0131301316013130130f0130c0130f01311013130131601316013110130f013130130f013110130f0130f013
__music__
00 02010344
06 06070344
00 02010344
01 4b4c0d4e
01 41420d44
01 41420d0e
01 41420d0e
01 410c0d0e
01 410c0d0e
01 0b0c0d0e
01 0b0c0d0e
01 0b0c0d0e
01 4b0c4d4e
03 0b0c0d0e
00 4b0c4d4e
03 0b0c0d0e
00 41424344
03 0b0c0d0e

