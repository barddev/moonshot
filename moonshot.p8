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
    -- g:change_state(menu)
    g:change_state(level_2)
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
    for e in all(self.eggs) do
        e:update()
    end
    p:update()
    c:update()
    baddies_update()
    bullets_update()
end

function level:draw()
    m:draw()
    for e in all(self.eggs) do
        e:draw()
    end
    p:draw()
    baddies_draw()
    bullets_draw()
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

    baddies = {
        baddie:new()
    }
    baddies[1]:init(vector2d(80,50))

end

-->8
-- level_2
level_2 = inherits_from(level)

function level_2:init()
    self.level = true
    self.level_num = 2
    m:init(vector2d(0,128), 1024)
    p:init(vector2d(0,128))
    c:init(vector2d(0,128))
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

    -- check picking up egg
    -- for e in all(eggs) do
    --     if tor_collision(e, self) then
    --         del(eggs, e)
    --     end
    -- end

    if self.health <= 0 then
        self:death()
    end


    -- globals.debug_var = self.sp

    self:animate()

end

function player:shoot()

    local dir = self:direction()

    local b = bullet:new()
    b:init(self.pos, 32, hitbox:new(5,2,3,3), 60, self.flip)

    sfx(10)
    add(bullets, b)
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

    self.pos += self.vel

    --limit to map
    if self.pos.x < m.start then
        self.pos.x = m.start
    end
    if self.pos.x > m.mend - self.w then
        self.pos.x = m.mend - self.w
    end 

    if self.pos.x >= m.mend - 15 then
        -- levelmanager:next_level()
        -- TODO: Switch to next level
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
        if b.health <= 0 then
            del(baddies, b)
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
    self.acc = vector2d(0.5, 0)
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
    self.bullet_max_time = 30

    self.grounded = false

    self.dir = -1
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
        globals.debug_var = m.pos.y + 128
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
    end

    -- check x direction
    -- left movement
    if self.vel.x < 0 then
        -- limit actor to max speed
        self.vel.x = mid(-self.max_vel.x, self.vel.x, self.max_vel.x)
        if self:map_collision("left", globals.solid) then
            self.vel.x = 0
            self.dir *= -1
        end
    -- right movement
    elseif self.vel.x > 0 then
        self.vel.x = mid(-self.max_vel.x, self.vel.x, self.max_vel.x)
        if self:map_collision("right", globals.solid) then
            self.vel.x = 0
            self.dir *= -1
        end
    end

    -- TODO remove this
    self.vel.x = 0
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
    -- c:init(vector2d())
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
00000998000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000a980bbbb3330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000bbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
0776d760007766dddd6677dd667ddd7766dd677d677d7d0055dd5555d55555550000000000000000000000000000000000000000dddddddddddddddddddddddd
d666dddd076666ddddd666dd666ddd66dddd66dd666dddd055dd5555557755550000000000000000000000000000000000000000177777777777777777777771
d66dd66dddd66dddd6ddddddd6dd66dddd6ddddd66dddddd555555d5557755d50000000000000000000000000000000000000000166666666666666666666661
ddddd66dddddddd6ddddd67ddddd66dddddd6dddddddd6dd55555555777775550000000000000000000000000000000000000000166666666666666666666661
dd5d6ddd6ddd6dddd555d66d5ddddd6ddddddddddd6ddddd5d555577755775550000000000000000000ddd000000000000000000111111111111111111111111
5d5ddd5dd6ddd5ddd555ddd555555dd5dd55d5dddd555ddd55777775555555550d000000000000d000d0d0000000000000000000000000000000000000000000
5d5dd555ddd555dd55d5555555dd5555d55555d55d55555d55777555555555d50d0d0000000000d000dd0d000000000000000000000000000000000000000000
555d5555d5555555555555d555dd55555d5555555555555dd557755d55d555550dd000000000d0d0000dddd00000000000000000000000000000000000000000
5555555555555dd55555555555555dd555555dd555555dd5dd555555000000000000000090000009000000006666666666666666000000005dddddd55dddddd5
5dd555d55d555dd55d5555555d555dd555d55dd555555dd5dd77777500000000000000004990009400000000666666666666666600000000d566665dd116665d
5dd55555555555555555d5555555555555555555d55555555577777700000000000000005449909400000000666666666666666600000000d666666dd616666d
55555d5555555d55555555555555555555555555555555555777dd7700000000000000000544494400000000666111111111166600000000d666666dd661616d
55dd55555555555555dd555555d555555d555d55555d555557d7dd7700000000000000000054444400000000666155100000066600000000d666666dd166166d
55dd55555dd5555555dd55555555dd5555dd555555555555557d777700000000000000000005444400000000666155100000066600000000d666666dd166166d
555555d55dd555d555555d555555dd5555dd5555dd55555555777ddd00000000046000000004444400000000666155100000066600000000d566665dd516665d
d5555555555555555555555555555555555555d5dd555d5557777d55000000000446656555544444000000006661551000000666000000005dddddd55dddddd5
dddddddddddddddd5d55dd6666d555d505555555555dd500000000000000000004455555555444441111116d666155100000066600000000d00000000000000d
1777777117777771555ddd6666dd5555555d5555555dd550000000000000000004500000000444441111116d666155100000066600000000d66667700776666d
166666611666666155d6ddddddddd555505555d555555500000000000000000000000000000444441111116d666155100000066600000000d76776777767767d
166666611655666155ddd5ddddddd55500555555555d5000000000000000000000000000000544441111116d666155100000066600000000d66666700766666d
166666611665666155d5555ddd55d55505555555d5555500000000000000000000000000005441141111116d666155100000066600000000d00000000000000d
16666661166656615555dd55d5dd555500055dd555555000000000000000000000000000054110111111116d666155100000066600000000d66666700766666d
16666661166666615d55dd5555dd55d505555dd555dd5550000000000000000000000000511000111111116d666155100000066600000000d77777777777777d
111111111111111155555555555555550055555555dd5500000000000000000000000000100000011111116d666155100000066600000000d66667600676666d
55dd555555d555555d5555d55555555500555555555555555555550000000000000000005111661111111111000000000000000000000000dddddddd00700070
d5dd55d555555dd555555555055d5dd5055d55555dd5d5505555d550000000000000000051116611111111110000000000000000000000000676066607770777
0555055055505dd55505d55505555dd5005555555dd5555055555500000000000000000051116611111111110000000000000000000000000666067607760776
5505505005050555555550050555555555555dd5555555505dd55555000000000000000051116611111111110000000000000000000000000676067606760676
0050d0000500050505005000005555555d555dd5555555005dd555d5000000000000000051116611111111110000000000000000000000000676067606760676
500000000050000505050050005dd55555555555555dd50055555555000000000000000051116611111111110000000000000000000000000766076606760666
000000000000000005000000055dd5d5055555555d5dd55055555550000000000000000051116611111111110000000000000000000000000770077006660666
00000000000000000000000055555555005555d5555555555d55550000000000000000005111661111111111000000000000000000000000007000700ddddddd
00000000555555555555555555555500000000000055555500000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000566666566666666566666666666666656666666500000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000566666566666666566666600000000000066666500000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000566666566666666566666666666666656666666500000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000555555555555555555555500000000000055555500000000000000000000000000000000000000000000000000242424000000000000000000000000
00000000566666665666666666656666666666666665666500000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000566666665666666666656666666666666665666500000000000000000000000000000000000000000000000024242424240000000000000000000000
00000000566666665666666666656666666666666665666500000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000566666665666666666656666666666666665666500000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000566666665666666666656666666666666665666500000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000555555555555555555555555555555555555555500000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000566666666666566666666666666656666666666500000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000566666666666566666666666666656666666666500000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000566666666666566666666666666656666666666500000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000566666666666566666666666666656666666666500000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000566666666666566666666666666656666666666500000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000005555555555555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000006666666666666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000006666666666666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000006666666666666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000005555555555555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000006665666665566666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000006665666666556666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000006665666666656666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000006665666666666666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000006665666666666666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000005555555555555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000006655666666665666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000006665666666665666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000006665566656665666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000006665666655665666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000006666666666665666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000001150000000000000050555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000000
00000000000001150606666000000050555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000000
00000000000811150555555000000050551111111111111111111111111111550000000000000000000000000000000000000000000000000000000000000000
00000888000811150505555000555550551b1111bbbb1bbbbbbb1111111b11550000000000000000000000000000000000000000000000000000000000000000
000008880008111500001000000050005511b111b1111b11b11b111111b111550000000000000000000000000000000000000000000000000000000000000000
0000077888881115000101000005050055111b11b1111b11b11b111111b111550000000000000000000000000000000000000000000000000000000000000000
0000088777771115000505000005050055111b11b1111b11b11b11111b1111550000000000000000000000000000000000000000000000000000000000000000
000007788888188500500050005000505511b111b1111b11111b1111b11111550000000000000000000000000000000000000000000000000000000000000000
00000887777787750000000000000000551b1111b1111b11111b1111b11111550000000000000000000000000000000000000000000000000000000000000000
0000077888887885000000000000000055111111111111111111111b111111550000000000000000000000000000000000000000000000000000000000000000
00000887777787750000000000000000551111111111111111111111111111550000000000000000000000000000000000000000000000000000000000000000
00000008888878850000000000000000551111111111111111111111111111550000000000000000000000000000000000000000000000000000000000000000
00000000000080050000000000000000551111111111111111111111111111550000000000000000000000000000000000000000000000000000000000000000
00000000000000050000000000000000551111111111111111111111111111550000000000000000000000000000000000000000000000000000000000000000
00000000000000050000000000000000551111111111111111111111111111550000000000000000000000000000000000000000000000000000000000000000
00000000000000050000000000000000551111111111111111111111111111550000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000551111111111111111111111111111550000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000551111111111111111111111111111550000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000556666665566666655555555555555550000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000556666665566666655555555555555550000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000555555555555555555555556666555550000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000556666566665666655555667777665550000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000556dd656bb65688655555677777765550000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000556dd656bb65688655556777777776550000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000556dd656bb65688655556777777776550000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000556dd656bb65688655556777777776550000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000556dd656bb65688655555677777765550000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000556dd656bb65688655555667777665550000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000556666566665666655555556666555550000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000000
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
0080808080808000000000000000000004000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000001010101010100000000000000010101010101010101000000000000000003030101010101010000000000000000202000000001010100000000000000002020
0100010101010000000000000000000001000101010100000000000000000000000001010000000000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000796a
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000796a
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000796a
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000796a
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000796a
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000796a
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011004800000000004a00000000000000000000000000000000000000000000000000000000000000000000796a
000000000000000000000000000000000000000000000000000000004a0000007f7f7f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000041424242424242424242450000000000000000000000000000000000000000000000000000000000000000796a
000000000000000000000000000000000000000000000000000000414444444442434343434500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000073515451505054505454720000000000000000000000000000000000000000000000000000000000000000796a
000000000000000000000000000000000000000000000000000000707170717070727172727200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000064505456505451506572000000000000000000000000000000000000000000000000000000000000000000796a
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004900000000000000000000000000000000000000000000000000000000000000735354545050515172000000000000000000000000000000007f7f00000000000000000000000000000000796a
000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000004145000000414500000000000000000000005e5e5e000000000000000000005e5e5e000000706453505252547600000000000000000000000000000000006060000000000000000000000000000000005b5c
0000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000064750000007475000000000000000000000000000000000000000000000000000000000000007151535250556245000000000000000000000000000060606061606000000000c0c100000000000000006b6c
0048000000004900004a000048000000110000006000001100000000004800000000000049000000110000490000736500000073757f7f000000494800000000000000000000005e5e5e00000000000000000000007064504647506500490000000000480000004a001160606160606000004a00d0d1480000c2c30049006b6c
4443434242444343424244424344424343444343444242434244444344424344444244434244424342434243424463750000007462434443444442424342450000000000000000000000000000000000000000000000735151505262444444424244424243444342434442424342444342424243424242434442424242424242
5054515451555055535155535452525250515555515253555453555151525152535555555354535046475350535552760000007350505050505050505050650000000000000000000000000000000000000000000000715050505050505050505050505050505050505050505050545050505050505050505050505050505050
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000796a
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000796a
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000796a
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000796a
000000000000000000000000000000000000444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000796a
00000000000000000000000000000000007e7e7e7e444400000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000796a
0000000000000000000000000000000000000000007e4444000000000000000000000043430000000000000000150042000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000796a
00000000000000000000000000000000000000000000444444000000000000000000006f4243434343424242424242546e000000000000000000000000000000005e5e5e5e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006060606000000000000000796a
000000000000000000000000000000000000000000007e7e7e00000000000000000000007e7e7e7e7e7e7e7e7e7e7e7e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005859796a
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000606060000000000000000000000043430000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006869796a
424200000000000000000000000000000000000000000000000000005e5e000000000000000000000000000000000000000000000000000000000000000000000000000000000043434300000000000000000000000000000000000000000000000000000000000000000000000000000000000000006060600000000000796a
4242420000000000000000000000000000000000000000000000007f00007f0000000000000000000000000000000000000000000000000000000000000000000000000000000043414343000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000796a
42424242420000000000000000110000410000000000000000005e000000005e00000000000000000000000000000000000000000000000000000000000000000000000000000043434343430000000000160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000796a
434343434343434343434242424242424200000042424242424242424242424200000000007f7f0000000000007f7f000000004242424242000000000000000000004242424242424242434342424242424242424242424242424242424242424242424242424242424242424242424242424242424242424242424242424242
4343434343434343434300000000000000000000000000000000000000000000424242424242424242424242424242424242424242424242000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4343434343434343434300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
011000200006300063030630000307625030000300000625005000006300063005000762503053005000050000063000630304300000076250300003000006250050000063000630050007625005000050000500
001000200a0100c0100c0100a01005010070100a0100c01011010130100f0100c0100c0100c0100f0101301016010130100f0100c0100f01011010130101601016010110100f010130100f010110100f0100f010
001000000077503705007050077500705007050077500705007050077500705007050077500705007750070500775037050070500775007050070500775007050070500775007050070503775007050077500705
011000000a0130c0130c0130a01305013070130a0130c01311013130130f0130c0130c0130c0130f0131301316013130130f0130c0130f01311013130131601316013110130f013130130f013110130f0130f013
000500000b06009060070500505003050020500005000050000500005000050000500000000000000000100002000020000000000000000000000000000000000000000000000000000000000000000000000000
0110002013c7013c7011c700fc700cc700ac700ac700ac7007c7007c7007c7007c7007c7007c7007c7007c7013c7013c7011c700fc700cc700ac700ac700ac7007c7007c7007c7007c7003c7003c7003c7003c70
011000200006300000030000006300000076000006300000000000006300000000000006300063000000000000063000000300000063000000760000063000000000000063000000000000063000630000007645
001800200fc7518c7516c7511c7511c7513c7513c750ac750cc750fc750ac7507c7505c7507c750ac7507c750fc7518c7516c7511c7511c7513c7513c750ac750cc750fc750ac7507c7505c7507c750ac7507c75
011800000007300000030000007300000076000007300000000000007300000000730007300073076350763500073000000300000073000000760000073000000000000073000000007300073000730763307635
011800200574005740037400374003740037400374003740057400574007740077400774007740037400374000740007400074000740007400374007740077400a7400a7400a7400a7400a740077400374003740
0130001013c6013c6013c6013c6013c6013c6016c6016c6013c6013c6013c6013c6018c6018c6016c6016c6000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c00
000800001695516955169551f9551f9551f9551f9551d9551d9551b9551d9501f9501d9501d9501b9551b95533900339003390000900009050090500905009050090500905009050090500905009050090500905
0030001013c6013c6013c6013c6013c6013c6016c6016c6013c6013c6013c6013c6018c6018c6016c6016c6000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c00
0118002005c7405c7403c7403c7403c7403c7403c7403c7405c7405c7407c7407c7407c7407c7403c7403c7400c7400c7400c7400c7400c7403c7407c7407c740ac740ac740ac740ac740ac7407c7403c7403c74
011800200fc7518c7516c7511c7511c7513c7513c750ac750cc750fc750ac7507c7505c7507c750ac7507c750fc7518c7516c7511c7511c7513c7513c750ac750cc750fc750ac7507c7505c7507c750ac7507c75
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
01 12535455
01 12531455
01 12531455
01 12131455
01 12131455
01 12131415
01 12131415
01 12131415
01 12131415
01 12131415
03 12131458
01 12135458

