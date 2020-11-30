pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- main
-- contains pico-8 main functions

function _init()
    m = gmap:new()
    g = game:new()
    p = player:new()
    c = cam:new()
    g:change_state(menu)
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

-- assumed globals
-- player p
-- game map m
-- game manager g
-- camera c
-- level manager l

globals = {
    -- application information
    title = "moonshot",
    version = "0.0.0",

    -- physics
    grav = 0.05,
    friction = 0.425,

    -- stars 
    stars_color_pal={1,2,9,12,13},

    -- debug information
    debug = true,
    debug_var = "",

    -- sprite flags
    solid = 0,
    egg = 3,
    invisible = 4,
    spike = 5,
    bullet = 6,

}

-->8
-- utils

-- inherit
-- http://lua-users.org/wiki/InheritanceTutorial

function inherits_from(base)
    local new_class = {}
    local class_mt = { __index = new_class }

    function new_class:new()
        local newinst = {}
        setmetatable(newinst, class_mt)
        return newinst
    end

    if base then
        setmetatable( new_class, { __index = base} )
    end

    return new_class
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
function hitbox:new(_x, _y, _w, _h)

    local o = {}
    setmetatable(o, hitbox)
    o.x = _x or 0
    o.y = _y or 0
    o.w = _w or 8
    o.h = _h or 8
    return o 

end

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

-- make any game updates
function game:update()
    self.state:update()
end

function game:draw()
    self.state:draw()

    if globals.debug
    and g.state.level then
        local row = 7
        print("var: " .. globals.debug_var, c.pos.x, 0 * row + c.pos.y, 9)
        print("p.pos: " .. p.pos, c.pos.x, 1 * row + c.pos.y, 9)
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
-- gmap
-- game map
gmap = {}

function gmap:new()
    local o={}
    setmetatable(o, self)
    self.__index = self
    return o
end

-- gmap:init initalize game map
-- pos: vector2d
-- length: map length 1024
-- stars: bool default is true
-- draw_map: determine if map should be drawn (not needed for menu)
--           default is true
function gmap:init(pos, length, stars, draw_map)

    local l = length or 1024
    local s = true
    local d = true
    if (stars ~= nil) s = stars
    if (draw_map ~= nil) d = draw_map

    self.pos = pos
    self.start = self.pos.x
    self.mend = self.pos.x + l
    self.stars = {}
    self.draw_map = d
    if s then
        self:stars_init()
    end

end

function gmap:stars_init()

  local perc = 0.05
  local num = flr((128 * perc) * (self.mend * perc))
  
  for i=1,num do
    s={}
    s.pos = vector2d()
    s.pos.x=rnd(m.mend)
    s.pos.y=rnd(128) + self.pos.y
    s.color=globals.stars_color_pal[
        flr(rnd(count(globals.stars_color_pal)))+1]
    s.size=flr(rnd(2))
    add(self.stars, s)
  end

end


-- update map
function gmap:update()
end

-- draw map
function gmap:draw()

    -- draw stars
    for s in all(self.stars) do
        local x = s.pos.x
        local y = s.pos.y
        rectfill(x, y, flr(x)+s.size, flr(y)+s.size, s.color)
    end

    -- draw map
    if self.draw_map then
        -- map(self.pos.x, self.pos.y)
        map(0, self.pos.y / 8, 0, self.pos.y)
    end

end

-->8
-- camera

cam = {}
function cam:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o 
end

function cam:init(pos)
    self.pos = pos
end

function cam:update()
    -- camera follows player
    self.pos.x = p.pos.x - 64 + (p.w / 2)

    -- end a gamescreen early from end
    if self.pos.x > m.mend - 128 then
        self.pos.x = m.mend - 128
        m.start = m.mend - 128
    end

    -- left end of camera doesnt move past start
    if (self.pos.x < m.start) then
        self.pos.x = m.start
    end


    camera(self.pos.x, self.pos.y)

end

-->8 
-- menu 
menu = {}

-- create menu
function menu:new()
    local o={}
    setmetatable(o, self)
    self.__index = self

    return o
end

-- menu:init
-- reset menu screen
function menu:init()
    -- map is just blank screen
    self.level = false

    m:init(vector2d(), 128, true, false)
    c:init(vector2d())
    camera(0,0)

    music(1)

end


-- menu:update
-- check if player wants to start
function  menu:update()
    if btnp(4) then
        -- start playing level 1
        g:change_state(level_1)
    end
end

-- menu:draw
-- draw menu screen
function  menu:draw()
    m:draw()
    print("press ❎", 50, 80, 7)
    print("deejay paredi", 41, 100, 5)
    print("patrick messina", 37, 106, 5)
    print("bard development", 0, 120, 5)
    print(globals.version, 109, 120, 5)
end


-->8
-- level
-- base class for all levels
level = {}
function level:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    self.eggs = {}
    return o 
end

-- initialize level
function level:init()
    -- init map to desired settings
    -- set baddies positions
    -- set up boss
    -- set up music
    -- set egg positions
    -- set up player
    -- set up camera
end

function level:update()
    for e in all(eggs) do
        e:update()
    end
    p:update()
    c:update()
    baddies_update()
    bullets_update()

end

function level:draw()
    m:draw()
    for e in all(eggs) do
        e:draw()
    end
    p:draw()
    baddies_draw()
    bullets_draw()

    for e in all(self.eggs) do
        e:draw()
    end
end

function level:player_position()
end

-->8
-- level_1

level_1 = inherits_from(level)

function level_1:init()
    self.level = true
    self.level_num = 1
    m:init(vector2d(), 1024)
    p:init(vector2d())
    c:init(vector2d())
    self:player_position()

    eggs = {}
    local _e = egg:new() 
    _e:init(vector2d(295, 53))
    add(eggs, _e)

    baddies = {
        baddie:new(),
        baddie:new(),
        baddie:new(),
        baddie:new(),
    }
    baddies[1]:init(vector2d(100,80))
    baddies[2]:init(vector2d(200,80))
    baddies[3]:init(vector2d(684,30))
    baddies[4]:init(vector2d(800,80))

    music(19)

end

function level_1:player_position()
    p.pos = vector2d(2, 104)
end

-->8
-- level_2
level_2 = inherits_from(level)

function level_2:init()
    self.level = true
    self.level_num = 2
    m:init(vector2d(0,128), 1024, false)
    -- p:init(vector2d(0,128))
    self:player_position()
    c:init(vector2d(0,128))

    eggs = {}
    local _e = egg:new() 
    _e:init(vector2d(377, 172))
    add(eggs, _e)

    baddies = {
        baddie:new(),
        baddie:new(),
        baddie:new(),
        boss:new(),
    }
    baddies[1]:init(vector2d(120,223))
    baddies[2]:init(vector2d(317, 176))
    baddies[3]:init(vector2d(676, 223))
    baddies[4]:init()

    music(3)

end


function level_2:player_position()
    p.pos = vector2d(20, 176)
end

-->8
-- actors
actor = {}
function actor:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o 
end

-- actor:init
function actor:init()
end

-- actor:animate
-- assumes 6 sprites
-- 1st is idle, 4 running, 1 jumping
-- in that order
-- all sprites should be in the same row
function actor:animate()
  
    if self.state == "jumping" then
        self.sp = self.base_sp + 5
    elseif self.state == "running" then

    if time() - self.anim > .1 then
      self.anim=time()
      self.sp += 1
      if self.sp > self.base_sp + 4 then
        self.sp = self.base_sp + 1
      end
    end

  else --player idle/falling
      self.sp = self.base_sp
  end
end

-- actor:jump
function actor:jump()
    sfx(00)
    self.jump_press = 0
    self.grounded_press = 0
    self.grounded = false

    self.vel.y -= self.acc.y 
end

-- actor:death
function actor:death()
end

-- actor:draw_lives
function actor:draw_lives()
end

function actor:shoot()
    -- local b = bullet:new(self.pos, 32, new_hitbox(5,2,3,3), 50, self.flip)
    -- sfx(10)
    -- add(bullets, b)
end

-- actor:update
-- update actor
function actor:update()
end

-- should be drawn
function actor:draw()
    self:draw_lives()
    spr(self.sp, self.pos.x, self.pos.y, 1, 1, self.flip, false)
    if globals.debug then 
        self:hitbox_draw(6)
    end
end

-- actor:direction
-- determine the direction actor is facing
-- returns -1 if facing left, 1 otherwise
function actor:direction(flip)

    if flip then
        return -1
    end
    return 1
end

-- actor:move
-- move the actor on screen
function actor:move()
end

function actor:hitbox_position()
    local dir = self:direction(self.flip)
    local x = 0
    local y = 0
    -- facing right
    if dir == 1 then
        x = self.hitbox.x
        y = self.hitbox.y
    else
        x = self.w - 1 - (self.hitbox.x + self.hitbox.w)
        y = self.h - 1 - (self.hitbox.y + self.hitbox.h)
    end

    return hitbox:new(x, y, self.hitbox.w, self.hitbox.h)
end

function actor:hitbox_abs_position()
    local h = self:hitbox_position()
    h.x += self.pos.x
    h.y += self.pos.y
    return h
end

function actor:hitbox_draw(c)
    local h = self:hitbox_abs_position()

    local x1 = h.x 
    local x2 = h.x + h.w
    local y1 = h.y
    local y2 = h.y + h.h
    rect(x1, y1, x2, y2, c)
end

function actor:collision(actor)
    local a =  self:hitbox_abs_position()
    local b = actor:hitbox_abs_position()

    if a.x < b.x + b.w
    and a.x + a.w > b.x
    and a.y < b.y + b.h
    and a.y + a.h > b.y then
        return true
    end
    return false
end


function actor:map_collision(direction, flag)

    -- TODO switch to hitbox
    local x=self.pos.x  local y=self.pos.y
    local w=self.w  local h=self.h
  
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

player = inherits_from(actor)

function player:init(pos)

    -- base sprite
    self.base_sp = 1
    self.sp = 1
    self.flip = false

    -- total sprite size
    self.w = 8
    self.h = 8

    -- pos: vector2d needs a starting position
    self.pos = pos

    -- hitbox: needs a hitbox
    self.hitbox = hitbox:new(1,0,6,7)

    self.anim = 0
    -- falling/running/jumping/idle
    self.state = "falling"
    self.health = 1
    self.lives = 3

    -- velocity
    self.vel = vector2d()
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

    self.bullet_sp = 32
    self.bullet_hitbox = hitbox:new(5, 2, 3, 3)
    self.bullet_distance = 60

end

function player:update()

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

    self:move()

    -- check if touched bad guy, if so die
    for b in all(baddies) do
        if self:collision(b) then
            self.health -= 1
        end
    end

    -- see if hit by bullet
    for b in all(bullets) do
        if b:collision(self) then
            self.health -= 1
            del(bullets, b)
        end
    end

    if self.health <= 0 then
        self:death()
    end


    -- globals.debug_var = self.sp

    self:animate()

    -- check picking up egg
    for e in all(eggs) do
        if self:collision(e) then
            del(eggs, e)
            self.lives += 1
            sfx(22)
        end
    end


end

function player:shoot()

    local dir = self:direction(self.flip)

    local b_pos = vector2d(self.pos.x, self.pos.y)

    -- -- facing right
    globals.debug_var = dir
    if dir == 1 then
    -- facing left
        b_pos.x += 3
    else
        b_pos.x -= 3
    end


    local b = bullet:new()
    b:init(b_pos, self.bullet_sp, self.bullet_hitbox,
        self.bullet_distance, self.flip)

    sfx(10)
    add(bullets, b)
end

function player:draw_lives()
    spr(48, c.pos.x + 110, c.pos.y)
    print("x" .. self.lives, c.pos.x + 120, c.pos.y, 9)
end

function player:death()
    self.lives -= 1
    self.health = 1
    if self.lives <= 0 then
        g:change_state(game_over)
    else
        g.state:player_position()
    end
end

function player:move()
    -- check y direction
    if self.vel.y > 0 then
        self.state = "falling"

        -- if player falls off the map
        if self.pos.y > m.pos.y + 128 then
            self.health -= self.health
            return
        end

        -- limit actor to max speed
        self.vel.y = mid(-self.max_vel.y, self.vel.y, self.max_vel.y)

        if self:map_collision("down", globals.solid) then
            self.grounded = true

            -- left/right movement
            -- TODO is actor really running if falling in the air
            -- fix this
            if self.vel.x != 0 then
                self.state = "running"
            else
                self.state = "idle"
            end
            self.vel.y = 0
            self.pos.y -= ((self.pos.y + self.h + 1) % 8) - 1
        end

        if self:map_collision("down", globals.spike) 
        or self:map_collision("up", globals.spike) 
        or self:map_collision("right", globals.spike) 
        or self:map_collision("left", globals.spike) then
            self.vel.y = 0
            self.health -= self.health
        end

    elseif self.vel.y < 0 then
        self.state = "jumping"
        if self:map_collision("up", globals.solid) then
            self.vel.y = 0
        end
    end

    -- check x direction
    -- left movement
    if self.vel.x < 0 then
        -- limit actor to max speed
        self.vel.x = mid(-self.max_vel.x, self.vel.x, self.max_vel.x)
        if self:map_collision("left", globals.solid) then
            self.vel.x = 0
        end
    -- right movement
    elseif self.vel.x > 0 then
        self.vel.x = mid(-self.max_vel.x, self.vel.x, self.max_vel.x)
        if self:map_collision("right", globals.solid) then
            self.vel.x = 0
        end
    end

    if self.vel.x == 0 then
        self.state = "idle"
    end

    self.pos += self.vel

    --limit to map
    if self.pos.x < m.start then
        self.pos.x = m.start
    end
    if self.pos.x > m.mend - self.w then
        self.pos.x = m.mend - self.w
    end 

    if self.pos.x >= m.mend - 15 then
        if g.state.level_num == 1 then
            g:change_state(level_2)
        end
    end


end

-->8
-->baddies

baddies = {}

function baddies_update()
    for b in all(baddies) do
        b:update()

        if b.boss then
            return
        end

        if b.health <= 0 then
            del(baddies, b)
            sfx(29)
        end
    end
end

function baddies_draw()
    for b in all(baddies) do
        b:draw()
    end
end

baddie = inherits_from(actor)

function baddie:init(pos)
    self.pos = pos
    self.vel = vector2d()
    self.acc = vector2d(0.3, 0)
    self.max_vel = vector2d(1, 2)
    self.state = "falling"

    self.base_sp = 17 
    self.sp = 17
    self.flip = false

    -- total sprite size
    self.w = 8
    self.h = 8

    self.anim = 0
    self.hitbox = hitbox:new(0,0,7,7)
    self.health = 3
    self.lives = 1

    -- bullet
    self.bullet_sp = 33
    self.bullet_hitbox = hitbox:new(1,2,7,2)
    self.bullet_timer = 0
    self.bullet_distance = 60
    self.bullet_max_time = 60

    self.grounded = false

    self.dir = -1

    self.boss = false
end

function baddie:update()
    self.vel.y += globals.grav
    self.vel.x *= globals.friction

    if self.grounded then
        self.vel.x += self.dir * self.acc.x
    else
        self.vel.x = 0
    end 

    self:move()

    self:shoot()

    -- check if hit by bullet
    for b in all(bullets) do
        if b:collision(self) then
            self.health -= 1
            del(bullets, b)
        end
    end

    if self.dir == 1 then 
        self.flip = false
    else
        self.flip = true
    end

    self:animate()

end

function baddie:move()
    -- check y direction
    if self.vel.y > 0 then
        self.state = "falling"

        -- if player falls off the map
        if self.pos.y > m.pos.y + 128 then
            self.health -= self.health
            return
        end

        -- limit actor to max speed
        self.vel.y = mid(-self.max_vel.y, self.vel.y, self.max_vel.y)

        if self:map_collision("down", globals.solid) 
        or self:map_collision("down", globals.invisible) then
            self.grounded = true

            -- left/right movement
            -- TODO is actor really running if falling in the air
            -- fix this
            if self.vel.x != 0 then
                self.state = "running"
            else
                self.state = "idle"
            end
            self.vel.y = 0
            self.pos.y -= ((self.pos.y + self.h + 1) % 8) - 1
        end

        if self:map_collision("down", globals.spike) 
        or self:map_collision("up", globals.spike) 
        or self:map_collision("right", globals.spike) 
        or self:map_collision("left", globals.spike) then
            self.vel.y = 0
            self.health -= self.health
        end
    end

    -- check x direction
    -- left movement
    if self.vel.x < 0 then
        -- limit actor to max speed
        self.vel.x = mid(-self.max_vel.x, self.vel.x, self.max_vel.x)
        if self:map_collision("left", globals.solid) 
        or self:map_collision("left", globals.invisible) then
            self.vel.x = 0
            self.dir *= -1
        end
    -- right movement
    elseif self.vel.x > 0 then
        self.vel.x = mid(-self.max_vel.x, self.vel.x, self.max_vel.x)
        if self:map_collision("right", globals.solid) 
        or self:map_collision("right", globals.invisible) then
            self.vel.x = 0
            self.dir *= -1
        end
    end

    self.pos += self.vel

end

-- badie shoot
function baddie:shoot()


    -- globals.debug_var = self.hitbox
    if self.bullet_timer <= self.bullet_max_time then
        self.bullet_timer += 1
        return
    end
    self.bullet_timer = 0



    local b_pos = vector2d(self.pos.x, self.pos.y)

    -- facing right
    if self.dir == 1 then
        if p.pos.x - self.pos.x < self.bullet_distance 
        and p.pos.x - self.pos.x > 0 then
            b_pos.x += self.w
        else
            return
        end

    -- facing left
    else
        if self.pos.x - p.pos.x < self.bullet_distance 
        and self.pos.x - p.pos.x > 0 then
            b_pos.x -= 7
        else
            return
        end
    end

    local b = bullet:new()

    b:init(b_pos, self.bullet_sp, self.bullet_hitbox, 60, self.flip)
    add(bullets, b)

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
        collide_wall = b:map_collision(direction, globals.solid)
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
            b:hitbox_draw(7)
        end

    end
end

bullet = inherits_from(actor)

function bullet:init(pos, sp, hitbox, distance, flip)
    self.pos = pos
    self.sp = sp
    self.flip = flip
    self.origin = pos
    self.distance = distance
    self.hitbox = hitbox
    self.w = 8
    self.h = 8
    self.vel = vector2d(1.5 * self:direction(flip), 0)

end

function bullet:update()
    self.pos += self.vel
end

-->8
-- game over 

game_win = {}

-- create menu
function game_win:new()
    local o={}
    setmetatable(o, self)
    self.__index = self

    return o
end

-- init win screen
function game_win:init()
    -- map is just blank screen
    self.level = false
    m:init(vector2d(), 128, true, false)
    music(38)

    m:init(vector2d(), 128, true, false)
    c:init(vector2d())
    -- c:update()
    -- m:update()
    camera(0,0)

    music(38)

end

-- menu:update
-- check if player wants to start
function  game_win:update()
    if btnp(4) then
        -- start playing level 1
        g:change_state(menu)
    end
end

function  game_win:draw()
    cls()
    m:draw()
    print("winner", 51, 60, 9)
end


game_over = {}

function game_over:new()
    local o={}
    setmetatable(o, self)
    self.__index = self
    return o
end


-- game_over:init
-- reset game_over screen
function game_over:init(win)
    self.win = win
    self.level = false
    -- map is just blank screen
    m:init(vector2d(), 128, true, false)
    c:init(vector2d())
    camera(0,0)
end

-- game_over:update
-- check if player wants to start
function  game_over:update()
    if btnp(4) then
        -- start playing level 1
        g:change_state(menu)
    end
end

-- game_over:draw
function  game_over:draw()
    m:draw()
    if self.win then
        print("you win!", 60, 60)
    else
        print("you lose, loser.", 60, 60)
    end
    print("press ❎", 50, 80, 7)
end

-->8
--> egg

eggs = {}

egg = inherits_from(actor)
-- create a new camera, map_end is the end of the camera
function egg:init(pos)
    local o = {}
    self.pos = pos
    self.sp = 16
    self.anim = 0
    self.hitbox = hitbox:new(0,0,8,8)
    self.vel = vector2d(0, 1)
end

function egg:update()
    self:animate()
end

function egg:draw()
    spr(self.sp, self.pos.x, self.pos.y)
end

function egg:animate()
  if time() - self.anim >.3 then
    self.anim = time()
    self.vel.y *= -1
    self.pos += self.vel
  end
end


boss = inherits_from(actor)

function boss:init()
    self.pos = vector2d(992, 200)
    self.vel = vector2d(0, 0.5)
    self.w = 16
    self.h = 16
    self.hitbox = hitbox:new(8, 0, 16, 16)
    self.sp = 88
    self.dir = 1

    self.boss = true

    -- TODO -h fix this
    self.health = 5
    self.lives = 1

    self.bullet_sp = 34
    self.bullet_hitbox = hitbox:new(0, 1, 8, 3)
    self.bullet_distance = 80
    self.bullet_timer  = 0
    self.bullet_max_time = 60

    self.shoot_timer = 0
    self.shoot_max_time = 30

    

end

function boss:update()

    if self.health <= 0 then
        g:change_state(game_win)
    end

    -- check if hit by bullet
    for b in all(bullets) do
        if b:collision(self) then
            self.health -= 1
            del(bullets, b)
        end
    end

    self:move()



end

function boss:draw()
    spr(self.sp, self.pos.x, self.pos.y)
    spr(self.sp+1, self.pos.x + 8, self.pos.y)
    spr(self.sp+16, self.pos.x, self.pos.y + 8)
    spr(self.sp+17, self.pos.x + 8, self.pos.y + 8)
end

function boss:move()

    -- globals.debug_var = self.hitbox
    if self.bullet_timer <= self.bullet_max_time then
        self.bullet_timer += 1
    else
        self.bullet_timer = 0
        self:shoot()
    end
    if self.pos.y >= 214 then
        self.vel *= -1
    end
    if self.pos.y <= 150 then
        self.vel *= -1
    end
    self.pos += self.vel

end

function boss:shoot()
    local b_pos = vector2d(self.pos.x-8, self.pos.y+4)
    local b = bullet:new()
    b:init(b_pos, self.bullet_sp, self.bullet_hitbox, 80, -1)
    add(bullets, b)
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
0000000000111d0000111d0000111d0000111d0000111d0000111d00000000000000000000000000000000000000000000000000000000000000000000000000
000ed000011aa9d0011aa9d0011aa9d0011aa9d0011aa9d0011aa9d0000000000000000000000000000000000000000000000000000000000000000000000000
00deee00011a99d0011a99d0011a99d0011a99d0011a99d0011a99d0000000000000000000000000000000000000000000000000000000000000000000000000
0ddeedd0011999d0011999d0011999d0011999d0011999d0011999d0000000000000000000000000000000000000000000000000000000000000000000000000
0eeeeed0061ddd00061ddd00061ddd00061ddd00061ddd00061ddd00000000000000000000000000000000000000000000000000000000000000000000000000
0eedeee0066655550666555506665555066655550666555506665555000000000000000000000000000000000000000000000000000000000000000000000000
0deddee00015dd000015dd000015dd000015dd000015dd000015dd00000000000000000000000000000000000000000000000000000000000000000000000000
00deee00000d0100000d0100000d100000010d000001d0000001d000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000a98000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000998000000008888822200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000a980bbbb3338888888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000bbbbbbb8888888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
0776d760007766dddd6677dd667ddd7766dd677d677d7d0055dd5555d55555550000000000000000000000000988998888aa8880dddddddd5dddddd55dddddd5
d666dddd076666ddddd666dd666ddd66dddd66dd666dddd055dd555555775555000000000000000000000000899889a888a9a88817777777d566665dd566665d
d66dd66dddd66dddd6ddddddd6dd66dddd6ddddd66dddddd555555d5557755d5000000000000000000000000888898a98999a88816666666d666666dd666666d
ddddd66dddddddd6ddddd67ddddd66dddddd6dddddddd6dd5555555577777555000000000000000000000000899aa8888a99988816666666d666666dd666666d
dd5d6ddd6ddd6dddd555d66d5ddddd6ddddddddddd6ddddd5d555577755775550000000000000000000ddd008999a9888aa998aa11111111d666666dd666666d
5d5ddd5dd6ddd5ddd555ddd555555dd5dd55d5dddd555ddd55777775555555550d000000000000d000d0d000a99999888888888a00000000d666666dd666666d
5d5dd555ddd555dd55d5555555dd5555d55555d55d55555d55777555555555d50d0d0000000000d000dd0d00aa9889999988889900000000d566665dd566665d
555d5555d5555555555555d555dd55555d5555555555555dd557755d55d555550dd000000000d0d0000dddd0aa88888899988999000000005dddddd55dddddd5
5555555555555dd55555555555555dd555555dd555555dd5dd55555500000000000000009000000900000000666666666666666698888a885dddddd55dddddd5
5dd555d55d555dd55d5555555d555dd555d55dd555555dd5dd77777500000000000000004990009400000000666666666666666699a88aa8d566665dd116665d
5dd55555555555555555d5555555555555555555d55555555577777700000000000000005449909400000000666666666666666699aa8899d666666dd616666d
55555d5555555d55555555555555555555555555555555555777dd770000000000000000054449440000000066611111111116669999a889d666666dd661616d
55dd55555555555555dd555555d555555d555d55555d555557d7dd77000000000000000000544444000000006661551000000666a9999889d666666dd166166d
55dd55555dd5555555dd55555555dd5555dd555555555555557d777700000000000000000005444400000000666155100000066689988988d666666dd166166d
555555d55dd555d555555d555555dd5555dd5555dd55555555777ddd00000000046000000004444400000000666155100000066688888888d566665dd516665d
d5555555555555555555555555555555555555d5dd555d5557777d550000000004466565555444440000000066615510000006668aa8aa885dddddd55dddddd5
dddddddddddddddd5d55dd6666d555d505555555555dd500055dd55555555d5004455555555444441111116d666155100000066699988aa9d00000000000000d
1777777117777771555ddd6666dd5555555d5555555dd550555dd55555dd550004500000000444441111116d6661551000000666988889a9d66667700776666d
166666611666666155d6ddddddddd555505555d5555555000055555d55dd550000000000000444441111116d6661551000000666988989a9d76776777767767d
166666611655666155ddd5ddddddd55500555555555d5000000555555555555000000000000544441111116d666155100000066699998889d66666700766666d
166666611665666155d5555ddd55d55505555555d555550005555d555555550000000000005441141111116d6661551000000666999a898ad00000000000000d
16666661166656615555dd55d5dd555500055dd555555000005555555555500000000000054110111111116d666155100000066699aa8998d66666700766666d
16666661166666615d55dd5555dd55d505555dd555dd5550055dd555dd5d555000000000511000111111116d666155100000066689888888d77777777777777d
111111111111111155555555555555550055555555dd5500555dd555dd55550000000000100000011111116d666155100000066688898888d66667600676666d
55dd555555d555555d5555d55555555500555555555555555555550000000000555555555111661111111111888888999888899999999899dddddddd00700070
d5dd55d555555dd555555555055d5dd5055d55555dd5d5505555d550000000005d5555d55111661111111111889aa88898998999989988890676066607770777
0555055055505dd55505d55505555dd5005555555dd5555055555500000000005555d5555111661111111111899888989988a88998a989890666067607760776
5505505005050555555550050555555555555dd5555555505dd5555500000000555555dd511166111111111199aa89998889a889a88a88990676067606760676
0050d0000500050505005000005555555d555dd5555555005dd555d50000000055dd55dd51116611111111119aa9889888889a88888aa8890676067606760676
500000000050000505050050005dd55555555555555dd500555555550000000055dd555551116611111111119999a8998899888a889888880766076606760666
000000000000000005000000055dd5d5055555555d5dd550555555500000000055555d5551116611111111119988aa8989888aa9888a988a0770077006660666
00000000000000000000000055555555005555d5555555555d5555000000000055555555511166111111111188888888898889988988a98a007000700ddddddd
00000000166666666666666116666661555555555555555555155555d555555555dd55555d5555555555555d0000000000000000000000000000000000000000
0000000015555555555555511555551655dd555555555555551555d5ddd555dd55dd5555d55555d55d55555d0000000000000000000000000000000000000000
0000000011111111111111111111115655dd555555ddd55511155555d6ddd5dd55555dd5dd55d5dddd555ddd0000000000000000000000000000000000000000
000000005555555555555dd5d55551565555555555ddd555555555556ddd6ddd5ddddd6ddddddddddd6ddddd0000000000000000000000000000000000000000
000000005555555555555dd5555551565555555555ddd5555555555dddddddd6dddd66dddddd6dddddddd6dd0000000000242424000000000000000000000000
000000005dd555555d55555555dd51565555555555555555555dd555ddd66dddd6dd66dddd6ddddd66dddddd0000000000000000000000000000000000000000
000000005dd555555555555555dd515655555dd555555555555dd555076666dd666ddd66dddd66dd666dddd00000000024242424240000000000000000000000
000000005555555555555555d555511155555dd5555555555d555555007766dd667ddd7766dd677d677d7d000000000000000000000000000000000000000000
0000000055555d55555ddd5516666661555555555555555555555155566666610000000000000000000000000000000000000000000000000000000000000000
0000000055555555555ddd556155555155d55555555555555d555155555555510000000000000000000000000000000000000000000000000000000000000000
0000000055555555555ddd556511111155555555555d555555555111111111110000000000000000000000000000000000000000000000000000000000000000
0000000055ddd555555555556515555d5555555555555555555555555555555d0000000000000000000000000000000000000000000000000000000000000000
0000000055ddd55555555555651555555555555dd5555555d5555555d55555550000000000000000000000000000000000000000000000000000000000000000
0000000055ddd5555dd555556515dd555555555dd5555555555dd55555d55dd50000000000000000000000000000000000000000000000000000000000000000
00000000555555555dd555d56515dd555d55555555555d55555dd55555555dd50000000000000000000000000000000000000000000000000000000000000000
0000000055555555555555551115555d5555555555555555555555d5555555550000000000000000000000000000000000000000000000000000000000000000
00000000d666666dd666666d11155555166666611666666166666661000000000000000000000000000000000000000000000000000000000000000000000000
000000005dddddd55dddddd56515dd55615555166155551655555516000000000000000000000000000000000000000000000000000000000000000000000000
000000005d6666d55d6666d56515dd55651111566511115611111156000000000000000000000000000000000000000000000000000000000000000000000000
000000005d6666d55d6666d5651555556515515665155156d5555156000000000000000000000000000000000000000000000000000000000000000000000000
000000005d6666d55d6666d565155555651551566515515655555156000000000000000000000000000000000000000000000000000000000000000000000000
000000005d6666d55d6666d5651555dd651d5156651d515655dd5156000000000000000000000000000000000000000000000000000000000000000000000000
000000005dddddd55dddddd5651555dd651551566515515655dd5156000000000000000000000000000000000000000000000000000000000000000000000000
00000000d555555dd555555d1115d5551115511111155111d5555111000000000000000000000000000000000000000000000000000000000000000000000000
00000000d666666dd666666d55555111166666655515515600000000000000000000000000000000000000000000000000000000000000000000000000000000
000000005dddddd55dddddd555dd5156155555555515515600000000000000000000000000000000000000000000000000000000000000000000000000000000
000000005d6666d55d6666d555dd5156111111111115515600000000000000000000000000000000000000000000000000000000000000000000000000000000
000000005d6666d55d6666d555555156d55555555555515600000000000000000000000000000000000000000000000000000000000000000000000000000000
000000005d6666d55d6666d5555551565555555d55dd515600000000000000000000000000000000000000000000000000000000000000000000000000000000
000000005d6666d55d6666d5dd5551565dd55d5555dd515600000000000000000000000000000000000000000000000000000000000000000000000000000000
000000005dddddd55dddddd5dd5551565dd555555555515600000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000d555555dd555555d555d5111555555555d55511100000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000001150000000000000050555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000000
00000000000001150606666000000050555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000000
00000000000811150555555000000050551111111111111111111111111111550000000000000000000000000000000000000000000000000000000000000000
00000888000811150505555000555550551b1111bbbb1bbbbbbb1111111b11550000000000000000000000000000000000000000000000000000000000000000
000008880008111500001000000050005511b111b1111b11b11b111111b111550000000000000000000000000000000000088888000000000000000000000000
0000077888881115000101000005050055111b11b1111b11b11b111111b111550000000000000000000000000000000008880033333300000000000000000000
0000088777771115000505000005050055111b11b1111b11b11b11111b1111550000000000000000000000000000000088003330800330000000000000000000
000007788888188500500050005000505511b111b1111b11111b1111b11111550000000000000000000000000000000080033000880030000000000000000000
00000887777787750000000000000000551b1111b1111b11111b1111b11111550000000000000000000000000000000083330000088033000000000000000000
0000077888887885000000000000000055111111111111111111111b111111550000000000000000000000000000000033000000008883330000000000000000
00000887777787750000000000000000551111111111111111111111111111550000000000000000000000000000000000000000000000000000000000000000
00000008888878850000000000000000551111111111111111111111111111550000000000000555555500000000000000000000000000000000000000000000
00000000000080050000000000000000551111111111111111111111111111550000000000055666666655000000000000000000000000000000000000000000
00000000000000050000000000000000551111111111111111111111111111550000000000566666661166500000000000000000000000000000000000000000
00000000000000050000000000000000551111111111111111111111111111550000000555566666666166555000000000000000000000000000000000000000
00000000000000050000000000000000551111111111111111111111111111550005555111466666666666511555500000000000000000000000000000000000
00000000000000000000000000000000551111111111111111111111111111550551111111466666666666511111155000000000000000000000000000000000
00000000000000000000000000000000551111111111111111111111111111555111111111144666666655111111111500000000000000000000000000000000
00110000000000000000011110000560555555555555555555555555555555554111111111111444444511111111111500000000000000000000000000000000
00110000000001100000155551006650556666665566666655555555555555550441111111111111111111111111155000000000000000000000000000000000
00006600000061100001555555165500556666665566666655555555555555550004444111111111111111111555500000000000000000000000000000000000
00000600000600000001555556650000555555555555555555555556666555550000000444444444444444444000000000000000000000000000000000000000
00000600006000000001555665510000556666566665666655555667777665550000000050000005000000050000000000000000000000000000000000000000
00000600006000000000155565510000556dd656bb65688655555677777765550000000500000005000000005000000000000000000000000000000000000000
00006000006000000000015555510000556dd656bb65688655556777777776550000005000000005000000000500000000000000000000000000000000000000
00006000006000000005551555510000556dd656bb65688655556777777776550000050000000005000000000050000000000000000000000000000000000000
00006000060000000005000111000000556dd656bb65688655556777777776550000500000000005000000000005000000000000000000000000000000000000
00000600600000000055000000000000556dd656bb65688655555677777765550005000000000005000000000000500000000000000000000000000000000000
00000606000000000055000000000000556dd656bb65688655555667777665550050000000000005000000000000050000000000000000000000000000000000
00000550000000000005500000000000556666566665666655555556666555550500000000000005000000000000005000000000000000000000000000000000
00005550000000000555555550000000555555555555555555555555555555555000000000000005000000000000000500000000000000000000000000000000
00011111000000005555555555000000555555555555555555555555555555550000000000000005000000000000000000000000000000000000000000000000
__label__
990099909990909009900c0090909990999099900990909000000000099090900000000099900000000090900000000099900000000000000000000000000000
90909000909090909000000090900900090090909090909009000000090090900900000090900000000090900900000090900000000000000000d00000000000
90909900990090909000000099900900090099009090090000000000990009000000000090900000000099900000000090900000000000000000000000000000
90909000909090909090000090900900090090909090909009000000090090900900000090900900000000900900000090900900000000000000000000000000
99909990999009909990000090909990090099909900909000000000099090900000000099909000000099900000000099909000000000000000000000000000
00000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000
00009090000000009990000000009090000000009990990000000000000000000000000000000000000000000000000000000000000000000000000000000000
00009090090000009090000000009090090000009090090000000000000000000000000000000000000000000000000000000000000000000000000000000000
00009090000000009990000000009990000000009990099000000000000000000000000000000000000000000000000000000000000000000000000000000000
00009990090000009090090000009090090000009090090000000000000000000000000000000000000000000000000000000000000000000000000000000000
00009990000000009990900000009090000000009990990000000000000900000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000090000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009900000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009900000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000dd0000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000dd0000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000099000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000099000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000220000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000220000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000100000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000cc00000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000cc00000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000220000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000220000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000c00000000000777077707770077007700000077777000000000000000000000000000000000000000000000000
0000000000000000000000cc00000000000000000000000000707070707000700070000000770707700000000000000000000000000000000000000000000000
0000000000000000000000cc00000000000000000000000000777077007700777077700000777077700000000000000000000000000000000000000000000009
00000009900000000000000000000000000000000000000000700070707000007000700000770707700000000000000000000000000000000000000000000000
00000009900000000000000000000000000000000000000000700070707770770077000000077777000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000009900000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000009900000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000090000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000002200000000000000550055505550555055505050000055505550555055505500555000000000000000000000000000009000000
00000000000000000000000002200000000000000505050005000050050505050000050505050505050005050050000000000000000000000000000000000000
00000000000000000000000000000000000000000505055005500050055505550000055505550550055005050050000000000000000000000000000000000000
000000000000000000000000000000000000000005050500050000500505000500000500050505050500050500500000000000000000d0000000000000000000
00000000000000000000000000000000000000000555055505550550050505550000050005050505055505550555000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000010000000000000000005550555055505550555005505050000055505550055005505550550055500000000000000000000000000000000
00000000000000000000000000000000000005050505005005050050050005050000055505000500050000500505050500000000000000000000000000000000
00000000000000000000000000000000000005550555005005500050050005500000050505500555055500500505055500000000000000000000000000000000
00000000000000000000000000000000000005000505005005050050050005050000050505000005000500500505050500000000000000000000009900000000
00000000000000000000000000000000000005000505005005050555005505050000050505550550055005550505050500000000000000000000009900000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cc0000
55505550555055000000550055505050555050000550555055505550550055500000000000000000000000000000000000000000000005550000055500cc0555
50505050505050500000505050005050500050005050505055505000505005200000000000000000000000000000000000000000000005050000050500000505
55005550550050500000505055005050550050005050555050505500505005000000000000000000000000000000000000000000000005050000050500000505
50505050505050500000505050005550500050005050500050505000505005000000000000000000000000020000000000000000000005050000050500000505
55505050505055500000555055500509555055505500500050505550505005000000000000000000000000000000000000000000000005550050055500500555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0080808080808000000000000000000004000000000000100000000000000000400000000000000000000000000000000000000000000000000000000000000001010101010100000000002020010003010101010101000000000000002003030101010101010101000001000020202000000001010101010001012020202020
0101010101010001010101000000000001010101010101010100000000000000000101010101010101000000000000000001010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000796a
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000796a
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000796a
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000796a
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000796a
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001700000000000000000000001700000000000000000000000000000000000000000000000000000000000000796a
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001700004800000000004a00001700000000000000000000000000000000000000000000000000000000000000796a
000000000000000000000000000000000000000000000000000000004a0000007f7f7f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001741424242424242424242451700000000000000000000000000000000000000000000000000000000000000796a
000000000000000000000000000000000000000000000000000000414444444442434343434500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000073515451505054505454720000000000000000000000000000000000000000000000000000000000000000796a
000000000000000000000000000000000000000000000000000000707170717070727172727200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000064505456505451506572000000000000000000000000000000000000000000000000000000000000000000796a
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004900000000000000000000000000000000000000000000000000000000000000735354545050515172000000000000000000000000000000007f7f00000000000000000000000000000000796a
000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000004145000000414500000000000000000000005e5e5e000000000000000000005e5e5e000000706453505252547600000000000000000000000000000000006060000000000000000000000000000000005b5c
0000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000064750000007475000000000000000000000000000000000000000000000000000000000000007151535250556245000000000000000000000000000060606061606000000000c0c100000000000000006b6c
0048000000004900004a000048000000000000006000000000000000004800000000000049000000000000490000736500000073757f7f000000494800000000000000000000005e5e5e00000000000000000000007064504647506500490000000000480000004a000060606160606000004a00d0d1480000c2c30049006b6c
4443434242444343424244424344424343444343444242434244444344424344444244434244424342434243424463750000007462434443444442424342450000000000000000000000000000000000000000000000735151505262444444424244424243444342434442424342444342424243424242434442424242424242
5054515451555055535155535452525250515555515153555453555151525152535555555354535046475350535552760000007350505050505050505050650000000000000000000000000000000000000000000000715050505050505050505050505050505050505050505050545050505050505050505050505050505050
7271707271707072707170727071707170645353535153535e5e5e5e5e5e5e5e5e5e5e7e7e7e7e7e7e7e7e7e7e7e7e7e0000005e5e5e5e5e5e5e52525e545e00000000000000000000000000000000004e7878787878785353535353535353535e5e5e5e0000000000000000000000000000000000000000000000000000796a
0000000000000000000000000000000000745154535153515e00000000000000000000000000000000000000000000000000000000000000005e53505e5e0000000000000000000000000000000000004e7878787878787853535353535353535e0000000000000000000000000000000000000000000000000000000000796a
0000000000000000000000000000000000665353525451535e000000000000000000000000000000000000000000000000000000000000000064525065000000000000000000000000000000000000005e5352535352545353535253535352535e0000000000000000000000000000000000000000000000000000000000796a
0000000000000000000000000000000000745353535353535e000000000000000000000000000000000000000000000000000000000000000070645265000000000000000000000000000000000000005e5352505354525452525452505054525e0000000000000000000000000000000000000000000000000000000000796a
0000000000000000000000000000000000645353535453535e000000000000000000000000000000000000000000000000000000000000000000727272000000000000000000000000000000000000005e5350525153535052535054525454535e0000000000000000000000000000000000000000000000000000000000796a
00000000000000000000000000000000007e7e7e7e5353525e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005e5353545354525354535353535352535e0000000000000000000000000000000000000000000000000000000000796a
0000000000000000000000000000000000000000007e54535e000000000000000000009383000000000000000000001700000000000000000000000000000000000000000000000000000000000000005e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e0000000000000000000000000000000000000000000000000000000000796a
0000000000000000000000000000000000000000000064535e000000000000000000006f9697818281828182818281836e000000000000000000000000000000005e5f5e5e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006060606000000000000000796a
000000000000000000000000000000000000000000007e7e7e00000000000000000000007e7e7e7e7e7e7e7e7e7e7e7e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000796a
8300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005e5e5e0000000000000000000000938300000000000000c8c9cacb0000c4c5c6c7000000000000000000000000000000000000000000000000000000000000000000000000796a
96a6000000000000000000000000000000000000000000000000000093830000000000000000000000000000000000000000000000000000000000000000000000000000000000a396a6000000000000d8d9dadbcccdd4d5d6d700000000000000000093834b5d7b7b4c9383000000000000000000006060600000000000796a
5496a60000000000000000000000000000000000000000000000007f54547f00000000000000000000000000000000000000000000000000000000000000000000000000000000a39196a60000000000e8e9eaebdcdde4e5e6e700000000000000009386b36d5d7b7b5da396830000000000000000000000000000000000796a
50859697a60000000000000000000000a4000000000000000000935450949483000000000000000000000000000000000000000000000000000000000000000000000000000000a3929296a600000000f8f9fafb0000f4f5f6f700000000000000938695b37b7b6d5d5da354968300000000000000000000000000000000796a
945384549697828182818281828182b4b50000009381828182b48694945151b300000000007f7f0000000000007f7f0000000093828182834b5d7c7d5d7d5d7c7c5d7c7c7c7c4ca392929296978281828182818281828182818281828182818281869584b37b7c7d7b4ca3525296979781828182818281828182818281828182
91529485539154505150519194959495b3000000a350529192919254925250969782818281828182818281828182818281828186929192b37c7b5d5d7b7c6d5d6d5d7c7c7c5d7ca352525252919295959592919291929192919291929192919291929192b37b5d5d7b5da3929192919254929192919291929192919291929192
52525252525252525252525252525252b3000000a354545452545454515451519192919291925454915491929192919254929192525152b37b7c7b7c7c7b6d7c5d6d7c7c5d7c7ca35454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454
__sfx__
010201000302006020090200b0100d010110501405004000030000300003000030000200002000010000000001000020000100001000010000100000000000000100002000020000200002000010000100001000
013000202772427714227241d724187141b73422724247341b73422714247241f714247242772429714247242772427714227141d724187141b72422714247141f7242271424714277141f724277242971426724
011800200003003030000300703107030070100701000000000300303000030070310703007010070100000000030030300003008031080300801008010000000003003030000300803108030080100c03007010
011800200c0330c0330c0333f003246150000000000246150c04300000000000c0430c0430c01324600246150c0330c0130c0430c0332461500000000000c03300000000000c033180230c033180002461524615
01300000135221352213522135221351213532135321353218532185221852218512185121851218512185122b5222e52233522335223352224532185421654218542185521b5521d5521f542225422453227522
0118002000043000430304300003076150300003000006150c05300000000000c0530c0530c01324600246150c0430c0230c0530c0432461300000000000c04000000000000c040180300c040180002461024610
01300010050300a0300c0400c0300c0400c0400a03007040050300503005020050300a0400a040050300304000000050300a0300c0400c0300c0400c0400a030070400500005000050000a0000a0000500003000
001800200f7301373116730187301b7301d7301b7301b7301873018730187301b7301f7301d73022730227301f7301f7301f7301b7301d73022730227301f7301f7301d7301d7301b7301b730167301873018730
000600000264012640066400463009620056100060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
0103000029f5024f5021f501ff501cf501bf5019f5018f5016f5015f5014f5013f5012f5011f5010f500ff500cf500af5009f5009f5008f5007f5007f5006f5005f5004f5003f5003f5004f5002f5001f5010f00
000400000b6100c6100d6100d6100e6100c6100a61009610086100761006610000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000200006300063030630000307625030000300000625005000006300063005000762503053005000050000063000630304300000076250300003000006250050000063000630050007625005000050000500
001000200a0100c0100c0100a01005010070100a0100c01011010130100f0100c0100c0100c0100f0101301016010130100f0100c0100f01011010130101601016010110100f010130100f010110100f0100f010
001000000077503705007050077500705007050077500705007050077500705007050077500705007750070500775037050070500775007050070500775007050070500775007050070503775007050077500705
011000000a0130c0130c0130a01305013070130a0130c01311013130130f0130c0130c0130c0130f0131301316013130130f0130c0130f01311013130131601316013110130f013130130f013110130f0130f013
000500000b04009040070300503003030020300003000030000300002000010000000000000000000000100002000020000000000000000000000000000000000000000000000000000000000000000000000000
0110002013c7013c7011c700fc700cc700ac700ac700ac7007c7007c7007c7007c7007c7007c7007c7007c7013c7013c7011c700fc700cc700ac700ac700ac7007c7007c7007c7007c7003c7003c7003c7003c70
011000200006300000030000006300000076000006300000000000006300000000000006300063000000000000063000000300000063000000760000063000000000000063000000000000063000630000007645
001800200fc7518c7516c7511c7511c7513c7513c750ac750cc750fc750ac7507c7505c7507c750ac7507c750fc7518c7516c7511c7511c7513c7513c750ac750cc750fc750ac7507c7505c7507c750ac7507c75
001800000007300000030000007300000076000007300000000000007300000000730007300073076350763500073000000300000073000000760000073000000000000073000000007300073000730763307635
011800200574005740037400374003740037400374003740057400574007740077400774007740037400374000740007400074000740007400374007740077400a7400a7400a7400a7400a740077400374003740
0130001013c6013c6013c6013c6013c6013c6016c6016c6013c6013c6013c6013c6018c6018c6016c6016c6000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c00
010500001697516975169751f9751f9751f9751f9751d9751d9751b9751d9701f9701d9701d9701b9751b97533900339003390000900009050090500905009050090500905009050090500905009050090500905
0030001013c6013c6013c6013c6013c6013c6016c6016c6013c6013c6013c6013c6018c6018c6016c6016c6000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c00
0118002005c7405c7403c7403c7403c7403c7403c7403c7405c7405c7407c7407c7407c7407c7403c7403c7400c7400c7400c7400c7400c7403c7407c7407c740ac740ac740ac740ac740ac7407c7403c7403c74
011800200fc7518c7516c7511c7511c7513c7513c750ac750cc750fc750ac7507c7505c7507c750ac7507c750fc7518c7516c7511c7511c7513c7513c750ac750cc750fc750ac7507c7505c7507c750ac7507c75
0104000011830118300f8300f8300f8300f83011830138301683016830118300f8300080000800008000080011830118300f8300f8300f8300f83011830138301683016830118300f83000800008000080000800
0004000004f2006f2007f3009f300af300cf300df300ff4010f4011f4012f4013f4015f5016f5018f5019f501af501bf501df501ff5020f5021f5022f5024f5006f5026f0028f0029f002af002cf002df002ef00
0103000029f5424f5421f541ff541cf541bf5419f5418f5416f5415f5414f5413f5412f5411f5410f540ff540cf540af5409f5409f5408f5407f5407f5406f5405f5404f5403f5403f5404f5402f5401f5410f04
010200002a053200531b053190531d05322053250531f053190531b05322053010530200002000030000200002003020030200302003020030200303003030030400305003050030400304003030030200301003
010e000005c5503c5507c5505c5507c550ac550ac550ac550fc550fc5511c5511c5513c5511c5513c5516c5516c5516c551bc551bc551bc5533c0533c5529c0533c551bc0500c0500c0500c0500c0500c0500c05
011400001fa531da531da531da531da531da531da531da531fa531fa531da531da531da531da531da531da531da531ba531ba531ba531ba531ba531ba531da531da531da531da531ba531ba531ba531ba531ba53
011800000007300000000730000007635076000000000073000000007300073000000763500000076350763500073000000007300000076350760000000000730007300073000000763500000076350763507635
011800200a7300a73007730077300773007730057300573007730077300a73005730077300773007730077300a7300a7300773007730077300773005730057300773007730077300773003730037300373003730
000d000024b3022b301db3018b2016b3013b300fb300ab1007b3005b1003b3000b2018b000bb001bb0022b0003b0000b0003b0003b0005b0005b0003b0003b0003b0000b0005b0003b0003b0000b000fb0003b00
01030000250202302022020200201d0201a020170201502014020110200e0200c0200702004020010200002000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 02010344
02 06070344
01 02010344
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
03 4b4c4d4e
03 10114344
01 04035455
01 12531455
01 12531455
01 12131455
01 12131455
03 12131415
01 12131415
01 12131415
01 12131415
03 12131415
01 52535458
01 1c535458
01 1c535458
01 1c535458
01 1c535458
00 09424344
00 49424344
00 1e5f4344
00 41424344
03 04060544

