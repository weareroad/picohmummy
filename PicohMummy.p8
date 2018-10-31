pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- pic-oh mummy
-- road software

function _init()
  init_system()
  
  setup_splash()
end


function _draw()
  if (scn==scr_game) then draw_game()
  elseif (scn==scr_lvl_clr) then draw_lvl_clr()
  elseif (scn==scr_menu) then draw_menu()
  elseif (scn==scr_gameover) then draw_gameover()
  elseif (scn==scr_highss) then draw_highss()
  elseif (scn==scr_settings) then draw_settings()
  elseif (scn==scr_new_pyramid) then draw_new_pyramid()
  elseif (scn==scr_enterhighscore) then draw_enterhighscore()
  elseif (scn==scr_splash) then draw_splash()
  else draw_instr()
  end
end


function _update()
  if (scn==scr_game) then upd_game()
  elseif (scn==scr_lvl_clr) then upd_lvl_clr()
  elseif (scn==scr_menu) then upd_menu()
  elseif (scn==scr_gameover) then upd_gameover()
  elseif (scn==scr_highss) then upd_highss()
  elseif (scn==scr_settings) then upd_settings()
  elseif (scn==scr_new_pyramid) then upd_new_pyramid()
  elseif (scn==scr_enterhighscore) then upd_enterhighscore()
  elseif (scn==scr_splash) then upd_splash()
  else upd_instructions()
  end
end


function draw_game()
  cls()
  map(0,0,0,0,16,16)

  print("score:"..padl(tostr(p.score),5,"0"),10,8,0)
  print("men:",72,8,0)
 
  -- show the scroll?
--  for l=1,min(p.scroll,3) do
--    if (l>0) spr(map_scrl,8+(l*8),16)
--  end
  if (p.scroll>0) then
    palt(0,false)
    spr(map_scrl,8,16)
    palt()
  end
    

  local sprites={}
  local frame=flr(p.frame) 
  if p.dir==dr_up then
    spr(pup[frame], p.x*8, (p.oldy*8)-p.frame+1)
    sprites=pup
  elseif p.dir==dr_down then
    spr(pdown[frame], p.x*8, (p.oldy*8)+p.frame-1)
    sprites=pdown
  elseif p.dir==dr_left then
    spr(pleft[frame], (p.oldx*8)-p.frame, p.y*8)
    sprites=pleft
  elseif p.dir==dr_right then
    spr(pright[frame], (p.oldx*8)+p.frame, p.y*8)
    sprites=pright
  end 
  
  -- indicate lives
  local sprite=frame
  for l=1,min(p.lives,5) do
    sprite+=1
    if (sprite>#sprites) sprite=1
    spr(sprites[sprite], 64+(l*8),16)
  end 
 
  for mmy in all(mummies) do
    if (mmy.active==true) and (mmy.reveal==false) then
      mframe=flr(mmy.frame)
      pal(mmy_col,mmy.color)
      if mmy.dir==dr_up then
        spr(mup[mframe], mmy.x*8, (mmy.oldy*8)-mmy.frame+1)
      elseif mmy.dir==dr_down then
        spr(mdown[mframe], mmy.x*8, (mmy.oldy*8)+mmy.frame-1)
      elseif mmy.dir==dr_left then
        spr(mleft[mframe], (mmy.oldx*8)-mmy.frame, mmy.y*8)
      elseif mmy.dir==dr_right then
        spr(mright[mframe], (mmy.oldx*8)+mmy.frame, mmy.y*8)
      end
      pal()
    elseif (mmy.reveal==true) and (mmy.frame<=#mreveal) then
      pal(mmy_tracker_col, mmy.color)
      spr(mreveal[mmy.frame], mmy.x*8, mmy.y*8)
      pal()
    end
  end
  
  if game_paused then
    rectfill(0,46,128,82,0)
    cnt_txt("paused", 62, 15)
  end
end



function upd_game()
  if game_paused then
    if btnp(5,0) then
      game_paused=false
      return
    end
  else
    upd_player()
    for mmy in all(mummies) do
      upd_mmy(mmy)
      if ((mmy.active==false) and (mmy.reveal==false)) del(mummies,mmy)
    end
    if btnp(5,0) then
      game_paused=true
      return
    end
  end
  
end


function upd_player()
  if (p.frame==1) and (p.x==p.oldx) and (p.y==p.oldy) then
  
    -- first off, set the floor as we have potentially just finished a move
    this_tile=mget(p.x, p.y)
    if (this_tile==map_walk) complete_step_and_check()
    -- level done?
    if (p.key>0) and (p.royal>0) and (p.x==door.x) and (p.y==door.y) then
      -- yep
      setup_lvl_clr()
      return
    end

    newx=p.x
    newy=p.y
    new_dir=p.dir
    if btn(0,0) then
      newx-=1
      new_dir=dr_left
    elseif btn(1,0) then
      newx+=1
      new_dir=dr_right
    elseif btn(2,0) then
      newy-=1
      new_dir=dr_up
    elseif btn(3,0) then
      newy+=1
      new_dir=dr_down
    end
  
    -- but can we make this move?
    if (newy!=p.y) or (newx!=p.x) then
      new_tile=mget(newx, newy)
      if fget(new_tile,flag_impass) then
        -- invalid move
        newx=p.x
        newy=p.y
      end
    end  
 
    -- trigger a move
    p.oldx=p.x
    p.oldy=p.y
    p.x=newx
    p.y=newy
    p.dir=new_dir
    -- update our footprints in the old tile
    mset(p.oldx,p.oldy,trav[p.dir])

  else
    -- ok we're potentially already moving
    if (p.x!=p.oldx) or (p.y!=p.oldy) then
      -- yup, move thru the anim
      p.frame=p.frame+p.speed
      if (p.frame>8) then
        p.frame=1
        p.oldx=p.x
        p.oldy=p.y
      end
    end
  end
end


function can_look(mmy, dirt)
  newx=mmy.x
  newy=mmy.y
  if (dirt==dr_up) newy-=1
  if (dirt==dr_down) newy+=1
  if (dirt==dr_left) newx-=1
  if (dirt==dr_right) newx+=1
   
  -- can we 'see' in this direction?
  new_tile=mget(newx,newy)
  -- not if it's an impass tile or the 'doorway'
  if (fget(new_tile,flag_impass)) or ((newx==door.x) and (newy==door.y)) then
    -- we can't see this way
    return false
  else
    return true
  end
end


function saw_player(mmy, dirt)
  -- which frame better to test, the previous one or the upcoming one?
  if p.frame<4 then
    testx=p.oldx
    testy=p.oldy
  else
    testx=p.x
    testy=p.y
  end

  if ((dirt==dr_up) and (mmy.x==testx) and (mmy.y>=testy)) return true
  if ((dirt==dr_down) and (mmy.x==testx) and (mmy.y<=testy)) return true
  if ((dirt==dr_left) and (mmy.y==testy) and (mmy.x>=testx)) return true
  if ((dirt==dr_right) and (mmy.y==testy) and (mmy.x<=testx)) return true
  return false
end


function smart_mmy_move(mmy)
  mmy.olddir=mmy.dir
  -- what are our surroundings?
  local chkup=can_look(mmy, dr_up)
  local chkdn=can_look(mmy, dr_down)
  local chklt=can_look(mmy, dr_left)
  local chkrt=can_look(mmy, dr_right)

  -- take away any 'behind'
  if (mmy.dir==dr_up) chkdn=false
  if (mmy.dir==dr_down) chkup=false
  if (mmy.dir==dr_left) chkrt=false
  if (mmy.dir==dr_right) chklt=false

  if chkdn and saw_player(mmy, dr_down) then
    mmy.dir=dr_down
  elseif chkup and saw_player(mmy, dr_up) then
    mmy.dir=dr_up
  elseif chklt and saw_player(mmy, dr_left) then
    mmy.dir=dr_left
  elseif chkrt and saw_player(mmy, dr_right) then
    mmy.dir=dr_right
  end

  -- have we changed, or do we still need to?
  if (mmy.change==true) and (mmy.dir==mmy.olddir) then
    dumb_mmy_move(mmy)
  end
end


function dumb_mmy_move(mmy)
  -- if we have 'change' then we need to swap direction
   mmy.olddir=mmy.dir
   mmy.dir=1+flr(rnd(dr_right))
   mmy.change=false
end


function check_mmy_collision(mmy)
-- which frame better to test, the previous one or the upcoming one?
  if p.frame<4 then
    testx=p.oldx
    testy=p.oldy
  else
    testx=p.x
    testy=p.y
  end

  -- improved collision detection - pick most suitable mummy frame too
  if mmy.frame<4 then
    mumx=mmy.oldx
    mumy=mmy.oldy
  else
    mumx=mmy.x
    mumy=mmy.y
  end

  if ((mumx==testx) and (mumy==testy)) then 
    -- mummy always dies
    mmy.active=false
    p.mmycount=safe_inc(p.mmycount)
    -- did we have the scroll?
    if p.scroll>0 then
      p.scroll-=1
      play_sfx(sfx_mmy_die)
      p.scount=safe_inc(p.scount)
    else
      -- lose a life
      p.lives-=1
      play_sfx(sfx_death)
      p.lostcount=safe_inc(p.lostcount)
      -- and it might be game-over
      if (p.lives<=0) scn=scr_gameover
    end
  end 
end



function validate_mmy_move(mmy)
  -- can we go in current dir?
  newx=mmy.x
  newy=mmy.y
  if (mmy.dir==dr_up) newy-=1
  if (mmy.dir==dr_down) newy+=1
  if (mmy.dir==dr_left) newx-=1
  if (mmy.dir==dr_right) newx+=1
   
  -- make this move?
  new_tile=mget(newx,newy)
  -- not if it's an impass tile or the 'doorway'
  if (fget(new_tile,flag_impass)) or ((newx==door.x) and (newy==door.y)) then
    -- okay we can't, next time we change direction    
    mmy.change=true
    newx=mmy.x
    newy=mmy.y
    mmy.dir=mmy.olddir
  end    
   
  if (newx!=mmy.x) or (newy!=mmy.y) then
    mmy.oldx=mmy.x
    mmy.oldy=mmy.y
    mmy.x=newx
    mmy.y=newy
  end
end


function mmy_reveal(mmy)
  mmy.frame+=1
  if (mmy.frame<=#mreveal) then
    mset(mmy.x,mmy.y,mreveal[mmy.frame])
  else
    mmy.frame=1
    mset(mmy.x,mmy.y,map_guard)
    mmy.reveal=false
    mmy.active=true
  end
end



function upd_mmy(mmy) 
  if (mmy.reveal==true) mmy_reveal(mmy)
  if (mmy.active!=true) return
 
  -- collision?
  check_mmy_collision(mmy)
  if (mmy.active!=true) return

  -- reached the tile we were walking towards?
  if (mmy.frame==1) and (mmy.x==mmy.oldx) and (mmy.y==mmy.oldy) then
    -- smart mummies constantly look to see what they can do
    if (mmy.tracker==true) then
      smart_mmy_move(mmy)
    -- dumb mummies don't
    elseif flr(rnd(8))==5 or mmy.change==true then
      dumb_mmy_move(mmy)
    end
    
    validate_mmy_move(mmy)
  else
    -- ok we're potentially already moving
    if (mmy.x!=mmy.oldx) or (mmy.y!=mmy.oldy) then
      mmy.frame=mmy.frame+mmy.speed
      if mmy.frame>8 then
        mmy.frame=1
        mmy.oldx=mmy.x
        mmy.oldy=mmy.y
      end
    end
  end
end


function upd_splash()
  scn_timer+=1
  if (btnp(5,0) or (scn_timer>200)) then
    setup_menu()
    if (game_music) music(0)
  end
end


function draw_splash()
  cls()
  -- moving very slightly to the left to centre the logo better
  map(16,0,-2,0,16,16)
  cnt_txt("proudly presents",76,6)
  cnt_txt(ttl,88,10)
  cnt_txt("road software 2018",108,5)
end


function setup_splash()
  scn_timer=1
  scn=scr_splash
end


function upd_gameover()
  if btnp(5,0) then
    while (btn(5,0)) do
    end
    if (p.score>high[#high].score) then
      setup_enterhighscore()
      scn=scr_enterhighscore
    else
      scn=scr_highss
    end
  end
end


function draw_gameover()
  cls()
  title("g a m e   o v e r",8)
  press_x()
  local xpos=12
  print("score              : "..padl(tostr(p.score),5,"0"),xpos,32,10)

  print("pyramids           : "..padl(tostr(p.pcount),5),xpos,42,6)
  print("level              : "..padl(tostr(p.level),5),xpos,48,6)
  print("steps taken        : "..padl(tostr(p.steps),5),xpos,54,6)
  print("mummies vanquished : "..padl(tostr(p.mmycount),5),xpos,60,6)
  print("men consumed       : "..padl(tostr(p.lostcount),5),xpos,66,6)
  print("scrolls used       : "..padl(tostr(p.scount),5),xpos,72,6)
  print("treasures found    : "..padl(tostr(p.tcount),5),xpos,78,6)

  -- beaten the lowest high score?
  if (p.score>high[#high].score) then
    cnt_txt("a new highscore table entry!", 100, 10)
  end
end 
 


function draw_menu()
  cls()
  title(ttl,8)
  press_x()

  local xpos=26
  high_line("", " play  game ", xpos, 38, menu_line==1, 10, 12)
  high_line("", "instructions", xpos, 58, menu_line==2, 10, 12)
  high_line("", "  settings  ", xpos, 78, menu_line==3, 10, 12)

  for men in all(c_ply) do
    spr(pright[men.frame], men.x, men.y)
  end

  for mum in all(c_mums) do
    pal(mmy_col, mum.color)
    spr(mright[mum.frame], mum.x, mum.y)
    pal()
  end
end


function setup_menu()
  c_mums={}
  c_ply={}
  local ofs=-5
  for i=1,flr(rnd(5))+1 do
    men={}
    men.x=ofs
    men.frame=flr(rnd(8))+1
    men.y=96
    add(c_ply,men)
    ofs=ofs-8
  end
  ofs=ofs-24
  for i=1,flr(rnd(13))+1 do
    mum={}
    mum.x=ofs
    mum.frame=flr(rnd(8))+1
    mum.y=96
    if flr(rnd(2))==0 then
      mum.color=mmy_col
    else
      mum.color=mmy_tracker_col
    end
    add(c_mums,mum)
    ofs=ofs-8
  end

  if scn!=scr_menu then
    scn_timer=1
    menu_line=1 -- reset the line to 'play game'
    scn=scr_menu
  end
end



function upd_menu()
  scn_timer+=1
  if scn_timer>300 then
    scn_timer=0
    scn=scr_highss
    return
  end
  
  for men in all(c_ply) do
    men.frame+=1
    if (men.frame>8) men.frame=1
    men.x=men.x+2
    if (men.x>128) del(c_ply, men)
  end

  for mum in all(c_mums) do
    mum.frame+=1
    if (mum.frame>8) mum.frame=1
    mum.x=mum.x+2
    if (mum.x>128) del(c_mums, mum)
  end
  
  if (#c_mums==0) then
    setup_menu()
  end

  if (btnp(2,0) and (menu_line>1)) then
    menu_line-=1
    scn_timer=1
  end
  if (btnp(3,0) and (menu_line<3)) then 
    menu_line+=1
    scn_timer=1
  end

  if btnp(5,0) then
    while (btn(5,0)) do
    end
    if menu_line==1 then
      init_game()
      scn=scr_game
    elseif menu_line==2 then
      scn=scr_instructions
    elseif menu_line==3 then
      scn=scr_settings
    end
  end
end


function draw_settings()
  cls()
  title("s e t t i n g s",8)
  press_x()
  local xpos=26
  high_line("game speed :",speeds[game_speed], xpos, 28, set_line==1, 10, 12)
  high_line("difficulty :",diffs[game_diff], xpos, 48, set_line==2, 10, 12)
  high_line("game music :",bool_as_switch(game_music), xpos, 68, set_line==3, 10, 12)
  high_line("game sound :",bool_as_switch(game_sound), xpos, 88, set_line==4, 10, 12)
end




function upd_settings()
  -- handle up & down
  if ((btnp(2,0) and (set_line>1))) set_line-=1
  if ((btnp(3,0) and (set_line<4))) set_line+=1
  new_game_music=game_music
  new_game_sound=game_sound

  if btnp(0,0) then
    if set_line==1 then
      if (game_speed>1) game_speed-=1
    elseif set_line==2 then
      if (game_diff>1) game_diff-=1
    elseif set_line==3 then
      new_game_music = not new_game_music
    elseif set_line==4 then
      new_game_sound = not new_game_sound
    end
  end

  if btnp(1,0) then
    if set_line==1 then
      if (game_speed<#speeds) game_speed+=1
    elseif set_line==2 then
      if (game_diff<#diffs) game_diff+=1
    elseif set_line==3 then
      new_game_music = not new_game_music
    elseif set_line==4 then
      new_game_sound = not new_game_sound
    end
  end

  if (new_game_sound!=game_sound) game_sound=new_game_sound

  if (new_game_music!=game_music) then
    game_music=new_game_music
    if game_music==false then
      music(-1)
    else
     music(0)
    end
  end

  if btnp(5,0) then
    -- wait until not pressed
    while (btn(5,0)) do
    end
    save_highs()
    scn_timer=1
    setup_menu()
  end
end


function draw_instr()
  cls()
  title("i n s t r u c t i o n s",8)
  press_x()

  if (instr_pg>instr_pc) instr_pg=1
  if instr_pg==1 then
    draw_instrp_01()
  elseif instr_pg==2 then
    draw_instrp_02()
  elseif instr_pg==3 then
    draw_instrp_03()
  elseif instr_pg==4 then
    draw_instrp_04()
  elseif instr_pg==5 then
    draw_instrp_05()
  elseif instr_pg==6 then
    draw_instrp_06()
  elseif instr_pg==7 then
    draw_instrp_07()
  elseif instr_pg==8 then
    draw_instrp_08()
  elseif instr_pg==9 then
    draw_instrp_09()
  end
end


function upd_instructions()
  if btnp(❎,0) then
    instr_pg+=1
    if (instr_pg>instr_pc) then
      reset_instructions()
      scn_timer=1
      setup_menu()
      return
    end
  end
end


function play_sfx(sfx_id)
  if (game_sound==true) sfx(sfx_id)
end


function draw_highss()
  cls()
  title(ttl,8)
  press_x()

  cnt_txt("todays best",20,6)
  print("score",20,32,5)
  print("lvl",48,32,5)
  print("explorer",72,32,5)
  local yline=46
  for x=1,5 do
    score=high[x]
    print(padl(tostr(x),2),5,yline,5)
    print(padl(tostr(score.score),5,"0"),20,yline,6)
    print(score.level,56,yline,6)
    print(score.name,72,yline,6)
    yline=yline+10
  end
end


function upd_new_pyramid()
  if btnp(5,0) then
      while (btn(5,0)) do
      end
      next_level()
  end
end


function draw_new_pyramid()
  cls()
  title(ttl,8)
  cnt_txt("!!  s t o p   p r e s s  !!",32,10)
  cnt_txt("british museum today announced",52,6)
  cnt_txt("successful excavation of ancient",58,6)
  cnt_txt("egyptian pyramid.",64,6)

  cnt_txt("leader of the team given",78,9)
  cnt_txt(pyrline,84,9)
  press_x()
end



function upd_highss()
  scn_timer+=1
  if (scn_timer>300) or (btnp(5,0)) then
    scn_timer=1
    setup_menu()
  end
end 


function draw_enterhighscore()
  cls()
  title("n e w   h i g h s c o r e!",8)
  cnt_txt("enter your name",20,6)

  print(">"..p.hname, 44,28,10)

  local curstart = 44 + 4 + (high_cp*4)
  line(curstart, 34, curstart+3, 34, 10)
  
  for curline=1,#highh do
    hiscore_helper(curline, 36 + (8*curline))
  end
  cnt_txt("select 'end' to complete",120,15)
end


function upd_enterhighscore()
  if (btnp(0,0) and high_sind>1) high_sind-=1
  if (btnp(1,0) and high_sind<6) high_sind+=1
  if (btnp(2,0) and high_sl>1) high_sl-=1
  if (btnp(3,0) and high_sl<#highh) high_sl+=1

  if btnp(5,0) then
    if (high_sl==#highh) then
      -- special ones
      if high_sind==1 then -- space
        add_hname(" ")
      elseif high_sind==2 then -- left
        if (high_cp>0) then
          high_cp-=1
        else
         bad_highs()
        end
      elseif high_sind==3 then -- right
        if high_cp<#p.hname then
          high_cp+=1
        else
          bad_highs() 
        end
      elseif high_sind==4 then -- delete
        handle_highs_delete()
      elseif high_sind==5 then -- clear whole name
        p.hname=""
        high_cp=0
      elseif high_sind==6 then -- end
        input_hiscore()
        save_highs()
        scn=scr_highss
      end
    else
      -- normal ones, just characters
      add_hname(highh[high_sl][high_sind])
    end
  end
end


function hiscore_helper(highline, ypos)
  local xpos=4

  for ind=1,#highh[highline] do
    -- get symbol, pad as required
    sym=highh[highline][ind]
    if #sym==1 then sym=" "..sym.." "
    elseif #sym==2 then sym=" "..sym
    end
    -- draw it
    if (highline==high_sl) and (ind==high_sind) then
      print(">"..sym.."<", xpos + (20*(ind-1)), ypos, 10)
    else
      print(" "..sym.." ", xpos + (20*(ind-1)), ypos, 12)
    end    
  end
end


function setup_enterhighscore()
  high_sind=1
  high_sl=1
  high_cp=#p.hname
end


function input_hiscore()
  -- pop through the table, insert high score in the right place
  for x=1,5 do
    if high[x].score<p.score then
      -- bubble them down
      if x<5 then
        for y=5,max(x,2),-1 do
          high[y].score=high[y-1].score
          high[y].level=high[y-1].level
          high[y].name=high[y-1].name
        end
      end
      -- it goes here
      high[x].score=p.score
      high[x].level=p.level
      high[x].name=p.hname   
      break
    end
  end
end


function padl(text,length,char)
  local chr = char or " "
  local res = text
  while #res<length do
    res=chr..res
  end
  return res
end


function padr(text,length,char)
  local chr = char or " "
  local res=text
  while #res<length do
    res=res..chr
  end
  return res
end


function title(text,colour)
  cnt_txt(text,6, colour)
end


function cnt_txt(text,ypos,colour)
  local pos = flr((128 - (4*#text)) / 2)
  print(text, pos, ypos, colour)
end


function press_x()
  cnt_txt("press ❎ ",120,15) -- extra space to overcome width of special 'x' char
end


function high_line(text,option,xpos,ypos,highlight,highlight_colour,plain_colour)
  if (#text!=0) print(text, xpos, ypos, plain_colour)
  
  if highlight==true then
    print("> "..option.." <", xpos + (#text*4)+4, ypos, highlight_colour)
  else
    print("  "..option.."  ", xpos + (#text*4)+4, ypos, plain_colour)
  end
end


function bad_highs()
  play_sfx(4) -- temp
end


function add_hname(char)
  if #p.hname<8 then
    p.hname=sub(p.hname,1,high_cp)..char..sub(p.hname,high_cp+1)
    high_cp+=1
  else
    bad_highs()
  end
end


function handle_highs_delete()
  if #p.hname>1 then
    if high_cp>=#p.hname then
      p.hname=sub(p.hname,1,#p.hname-1)
      high_cp-=1
    else
      if (high_cp==0) then
        if (#p.hname>1) then 
          p.hname=sub(p.hname,2)
        else
          bad_highs()
        end
      else
        p.hname=sub(p.hname,1,high_cp)..sub(p.hname,high_cp+2)
        high_cp-=1
      end
    end
  else
    if (#p.hname==0) bad_highs()
    p.hname=""
    high_cp=0
  end
end


function setup_lvl_clr()
  c_mums={}
  c_ply={}
  
  local ofs=-5
  for i=1,p.lives do
    men={}
    men.x=ofs
    men.frame=flr(rnd(8))+1
    men.y=80
    add(c_ply,men)
    ofs=ofs-8
  end
  ofs=ofs-24

  -- cleared a pyramid, time to reset stuff
  if (p.level % pyramid_modulo) == 0 then
    -- delete all mummies
    for mmy in all(mummies) do
      del(mummies,mmy)
    end

    -- inc difficulty, unless already on oh mummy, in which case inc speed
    if (p.gdiff<#diffs) then
      p.gdiff+=1
    elseif (p.gspeed<#speeds) then
      p.gspeed+=1
      p.speed=choose_player_speed()
    end
  end

  if #mummies>0 then
    for i=1,#mummies do
      -- any emerging mummies we need to carry over?
      if mummies[i].reveal then
        mummies[i].frame=1
        mummies[i].reveal=false
        mummies[i].active=true
        mummies[i].x=13
        mummies[i].y=12
        mummies[i].dir=dr_left
        mummies[i].active=true
      end

      if mummies[i].active then
        mum={}
        mum.x=ofs
        mum.frame=flr(rnd(8))+1
        mum.y=80
        mum.color=mummies[i].color
        add(c_mums,mum)
        ofs=ofs-8
      end
    end
  end

  scn=scr_lvl_clr
end


function draw_lvl_clr()
  cls()
  cnt_txt("level "..p.level.." cleared",50,6)
  for men in all(c_ply) do
    spr(pright[men.frame], men.x, men.y)
  end

  for mum in all(c_mums) do
    pal(mmy_col, mum.color)
    spr(mright[mum.frame], mum.x, mum.y)
    pal()
  end
  press_x()
end


function upd_lvl_clr()
  for men in all(c_ply) do
    men.frame+=1
    if (men.frame>8) men.frame=1
    men.x=men.x+2
    if (men.x>128) del(c_ply, men)
  end

  for mum in all(c_mums) do
    mum.frame+=1
    if (mum.frame>8) mum.frame=1
    mum.x=mum.x+2
    if (mum.x>128) del(c_mums, mum)
  end
  
  if (#c_mums<1) and (#c_ply<1) then
    setup_lvl_clr()
  end

  if btnp(5,0) then
    if (p.level % pyramid_modulo) == 0 then
      handle_new_pyramid()
    else
     next_level()
    end
  end
end


function next_level()
  p.level+=1
  reset_level()
  scn=scr_game
end

function handle_new_pyramid()
  p.pcount=safe_inc(p.pcount)
  
  if p.lives==5 then
    -- add treasure
    p.score = safe_inc(p.score, 50 + (flr(rnd(6))*10))
    pyrline="extra loot as a reward"
  else
    -- add lives
    p.lives+=1
    pyrline="extra man for next dig"
  end
  scn=scr_new_pyramid
end


function bool_as_switch(bool)
  if bool then
    return "on "
  else
    return "off"
  end
end


function reset_level()
  p.key=0
  p.scroll=0
  p.royal=0

  -- just reset the map contents for now
  for x=2,14 do
    for y=3,13 do
      local tile=mget(x,y)
      travd=fget(tile,travd_flag)
      if (travd) mset(x,y,map_walk)
    end
  end
 
  for x=0,4 do
    for y=0,3 do
      mx=map_ofx+(x*2)+1
      my=map_ofy+(y*2)+1
      -- pick unopened colour from array
      mset(mx,my,map_unopened[1+(p.level % #map_unopened)])
      chests[x+1][y+1]=map_chst
      -- anything left as map_chst
      -- when open now is an 'empty' chest
    end
  end
 
  -- now set the goodies
  set_chest(map_guard)
  set_chest(map_key)
  set_chest(map_royal)
  set_chest(map_scrl)

  for x=1,10 do
    -- on hardest diff, 1:3 chance of swapping treasure for something else
    -- arbitrarily picked iteration=8 to see if anyone is reading
    if (game_diff==4) and (x==8) and (flr(rnd(3))==0) then
      -- 1:3 chance of it being a scroll
      if (flr(rnd(3))!=0) then
        -- ok it's a tracker, ha ha
        set_chest(map_guard)
      end
    else
      set_chest(map_trsr)
    end
  end

  add_mmy(13,12,dr_up,false,false) -- not 'reveal', not 'smart'
end         


function set_chest(tile)
  done=false
  while (done==false) do
    x=1+ flr(rnd(5))
    y=1+ flr(rnd(4))
    if chests[x][y]==map_chst then
      chests[x][y]=tile
      done=true
    end
  end
end         


function choose_mmy_tracker()
   return (p.gdiff>1) -- maps 1,2,3,4, no trackers on lowest level
end


function choose_mmy_speed(tracker)
  -- normal behaviour
  local speed=0.5*p.gspeed -- map from 1, 2, 3 to 0.5, 1, 1.5
  
  if tracker then
    if (p.gdiff>2) speed=max(speed+0.5,1.5) -- max out at 1.5
  end
  return speed
end


function choose_player_speed()
  return 0.5*p.gspeed -- map it to 0.5, 1, 1.5
end


function add_mmy(x,y,dir,reveal,tracker)
  -- if it's got silly, don't bother
  if (#mummies>max_mummies) return

  mmy={}
  mmy.x=x
  mmy.y=y
  mmy.frame=1
  mmy.loop=0
  mmy.reveal=reveal
  mmy.active=not reveal
  mmy.oldx=x
  mmy.oldy=y
  mmy.dir=dir
  mmy.olddir=mmy.dir
  mmy.tracker=tracker
  if tracker then
    mmy.color=mmy_tracker_col
  else
    mmy.color=mmy_col 
  end

  mmy.change=false -- flip when we know we need to change direction
  mmy.speed=choose_mmy_speed(tracker)

  add(mummies,mmy)
end

function complete_step_and_check()
  -- we've just completed a move
  mset(p.x,p.y,trav[p.dir])
  p.steps=safe_inc(p.steps)
  -- check to see if we just boxed-off a chest...
  for x=0,4 do
    for y=0,3 do
      mx=map_ofx+(x*2)+1
      my=map_ofy+(y*2)+1
      tile=mget(mx,my)
      -- unopened chest?
      if tile==map_unopened[1+(p.level%#map_unopened)] then
        -- so, are the 8 spaces around it travd?      
        cleared=true
        for p=mx-1,mx+1 do
          for q=my-1,my+1 do
            tile=mget(p,q)
            travd=fget(tile,travd_flag)
            -- don't check the centre
            if (p!=mx) or (q!=my) then
              cleared=cleared and travd
            end
          end
        end
        if cleared then
          mset(mx,my,chests[x+1][y+1])
          opened_chest(x+1,y+1,mx,my)
        end
      end
    end
  end
end

-- we have just opened this chest
function opened_chest(cx,cy,mx,my)
  content=chests[cx][cy]
  if content==map_key then
    p.key+=1
    play_sfx(sfx_key)
  elseif content==map_scrl then
    p.scroll+=1
    play_sfx(sfx_scroll)
    p.scount=safe_inc(p.scount)
  elseif content==map_royal then
    p.royal+=1
    p.score = safe_inc(p.score,50)
    play_sfx(sfx_royal)
  elseif content==map_guard then
    add_mmy(mx, my, dr_down, true, choose_mmy_tracker())
    play_sfx(sfx_guard_free)
  elseif content==map_trsr then
    p.score = safe_inc(p.score,5)
    play_sfx(sfx_treasure)
    p.tcount=safe_inc(p.tcount)
  else
    -- empty chest
    mset(mx,my,map_chst_empty)
    play_sfx(sfx_nothing)
  end
end


-- inc a variable without overflowing
function safe_inc(value,amount)
  local add=amount or 1
  if value < (32767-add) then
    return value+add
  else
    return value
  end
end


function init_game()
  game_paused=false
  p.lives=5
  p.level=1
  p.dir=dr_down
  p.x=door.x
  p.y=door.y
  p.oldx=p.x
  p.oldy=p.y
  p.scount=0
  p.tcount=0
  p.lostcount=0
  p.mmycount=0
  p.pcount=1
  p.hname=""
  p.gspeed=game_speed
  p.gdiff=game_diff
  p.speed=choose_player_speed()
   -- 0.5, 1 or 1.5

  p.score=0
  p.frame=1
  p.steps=0

  for mmy in all(mummies) do
    del(mummies,mmy)
  end

  reset_level()
  scn=scr_game 
end


function reset_instructions()
  instr_pg=1
end


function init_system()
  ttl="p i c o h  -  m u m m y !"
  cartdata("road_software_picoh_mummy_internalv01")
  menuitem(4,"reset high scores",function() clear_highs() end)
  store_flag=48  -- increement/change this to cause it to not see saved data

  create_ascii()

  -- animation frames, player
  pright={2,1,1,2,2,1,1,2}
  pleft={18,17,17,18,18,17,17,18}
  pdown={35,34,34,35,35,33,33,35}
  pup={51,50,50,51,51,49,49,51}
  -- mummies
  mright={10,9,9,10,10,9,9,10}
  mleft={26,25,25,26,26,25,25,26}
  mdown={43,42,42,43,43,41,41,43}
  mup={59,58,58,59,59,57,57,59}

  -- crude but avoids messing up main routine just for this
  mreveal={39,39,39,39,12,12,12,12,12,13,13,13,13,13,14,14,14,14,14,15,15,15,15,15,28,28,28,28,28,29,29,29,29,29,30,30,30,30,30,31,31}

	-- weird order here because of how we calculate using modulo
  map_unopened={63,44,45,46,47,60,61,62}

  -- footsteps - not animation, but same kind of array of sprites
  trav={40,56,8,24} 

  -- general constants
  dr_up=1
  dr_down=2
  dr_left=3
  dr_right=4
  trav_right=24
  trav_left=8
  trav_up=40
  trav_down=56

  pyramid_modulo = 5 -- how many levels per pyramid?

  -- scn 'id' constants 
  scr_menu=0
  scr_game=1
  scr_gameover=2
  scr_highss=3
  scr_lvl_clr=4
  scr_settings=5
  scr_instructions=6
  scr_new_pyramid=7
  scr_enterhighscore=8
  scr_splash=9

  -- used for tracking current scn, frame timers etc
  scn=scr_menu
  scn_timer=0
  menu_line=1
  set_line=1
  high_sind=1
  high_sl=1

  c_mums={}
  c_ply={}
  -- overridden by the player if required
  speeds={}
  speeds[1]="moderate" --"slow"
  speeds[2]="regular"
  speeds[3]="murderous" -- "fast"
  
  diffs={}
  diffs[1]="easy"
  diffs[2]="normal"
  diffs[3]="hard"
  diffs[4]="oh mummy!"

  -- sfx constants
  sfx_treasure=4
  sfx_royal=5
  sfx_key=5
  sfx_death=6
  sfx_mmy_die=7

  -- map tile <-> sprite constants
  map_walk = 55 -- where we can go
  map_chst = 37 -- default unopened chest
  map_chst_empty = 39 -- dark, empty chest
  map_key  = 21 -- key
  map_scrl = 22 -- scroll
  map_royal= 23 -- sleeping mmy
  map_trsr = 38 -- treasure
  map_guard= 54
  spr_player_life = 1

  -- set this bit on all tiles that cant be 'crossed'
  impass_flag=0 
  -- used to help track footprints
  travd_flag=1 

  -- this is the spawn-point, exit and 'safe tile'
  door={}
  door.x=7
  door.y=3 
 
  p={} -- holds the player
  mummies={} -- holds the mummies
  create_chest_array() -- tracks what is in the chests
  max_mummies = 20 -- max onscn 
  mmy_col = 10 -- colour of dumb mummies
  mmy_tracker_col = 12 -- colour of smart mummies
 
  -- where does the play area start, basically?
  map_ofx=3
  map_ofy=4
  setup_highhs()
  load_highs()

  instr_pc=9
  reset_instructions()
end


function create_chest_array()
  chests={}
  for x=1,5 do
    chests[x]={}
    for y=1,4 do
      chests[x][y]=0
    end
  end
end


function load_highs()
  -- ever been saved?
  if dget(0)!=store_flag then
    clear_highs()
    return
  end

  high={}
  for x=1,5 do
    score={}
    score.score=0
    score.level=1
    score.name="        "
    add(high,score)
  end
  game_sound=num_to_bool(dget(1))
  game_music=num_to_bool(dget(2))
  game_diff=dget(3)
  game_speed=dget(4)

  ofs=5
  for x=0,4 do
    tstr=""
    for y=0,7 do
      f=dget(ofs+(y+(x*12)))
      tstr=tstr..chr(f) 
    end
    high[1+x].name=tstr
    high[1+x].level=dget(ofs+(8+(x*12)))
    high[1+x].score=dget(ofs+(9+(x*12)))
  end

end


function create_ascii()
  chars=" !\"#$%&'()*+,-./0123456789:;<=>?@abcdefghijklmnopqrstuvwxyz[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"
  -- '
  s2c={}
  c2s={}
  for i=1,95 do
   c=i+31
   s=sub(chars,i,i)
   c2s[c]=s
   s2c[s]=c
  end
end

function chr(i)
 return c2s[i]
end

function ord(s,i)
 return s2c[sub(s,i or 1,i or 1)]
end

function save_highs()
  dset(0,store_flag) -- indicate we've saved data
  dset(1,bool_to_num(game_sound))
  dset(2,bool_to_num(game_music))
  dset(3,game_diff)
  dset(4,game_speed)

  ofs=5
  for x=0,4 do
    tstr=high[1+x].name.."        "  -- need to have 8 chars
    tstr=sub(tstr,1,9)
    for y=0,7 do
      print(ofs+(y+(x*12)), sub(tstr,1+y,1+y))
      dset(ofs+(y+(x*12)), ord(tstr,1+y))
    end
    dset(ofs+(8+(x*12)), high[1+x].level)
    dset(ofs+(9+(x*12)), high[1+x].score)
  end
end

function bool_to_num(bool)
  if bool then return 1
  else return 0
  end
end

function num_to_bool(num)
  return (num==1)
end


function clear_highs()
  cls()
  high={}
  for x=1,5 do
    score={}
    score.score=100 + ((5-x)*50)
    score.level = flr(score.score/100)
    score.name="king tut"
    add(high,score)
    --print(high[x].score)
  end
  game_speed=2
  game_diff=2
  game_sound=true
  game_music=true
  
  save_highs()
end


function setup_highhs()
  highh={}
  tmpline={"a","b","c","d","e","f"}
  add(highh,tmpline)
  tmpline={"g","h","i","j","k","l"}
  add(highh,tmpline)
  tmpline={"m","n","o","p","q","r"}
  add(highh,tmpline)
  tmpline={"s","t","u","v","w","x"}
  add(highh,tmpline)
  tmpline={"y","z","0","1","2","3"}
  add(highh,tmpline)
  tmpline={"4","5","6","7","8","9"}
  add(highh,tmpline)
  tmpline={"!","&","+","=","-","*"}
  add(highh,tmpline)
  tmpline={"spc","<",">","del","clr","end"}
  add(highh,tmpline)
end


-- special version that works with the global varialbe instr_y
function instr_text(text,colour)
  local pos = flr((128 - (4*#text)) / 2)
  print(text, pos, instr_y, colour)
  instr_y+=6
end


function draw_instrp_01()
  instr_y=18
  instr_text("you have been appointed head of",6)
  instr_text("an archaeological expedition, ",6)
  instr_text("sponsored by the british museum,",6)
  instr_text("and have been sent to egypt to ",6)
  instr_text("explore newly found pyramids. ",6)
  instr_y+=6
  instr_text("your party consists of 5 members",6)
  instr_y+=3
  spr(1,60, instr_y)
  instr_y+=12
  instr_text("your task is to enter the 5",6)
  instr_text("levels of each pyramid, and",6)
  instr_text("recover from them 5 royal",6)
  instr_text("mummies and as much treasure",6)
  instr_text("as you can.",6)
  instr_y+=3
  spr (23,50, instr_y)
  spr (38,70, instr_y)
end

function draw_instrp_02()
  instr_y=18
  instr_text("each level has been partly",6)
  instr_text("uncovered by local workers and",6)
  instr_text("it's up to your team to finish",6)
  instr_text("the dig. unfortunately, the",6)
  instr_text("workers aroused guardians left",6)
  instr_text("behind by the ancient pharoahs",6)
  instr_text("to protect their tombs.",6)
  instr_y+=6
  instr_text("each level has 2 guardian",6)
  instr_text("mummies, one lies hidden while",6)
  instr_text("the other one searches for",6)
  instr_text("intruders.",6)
  instr_y+=3
  spr(9, 50, instr_y)
  pal(mmy_col, mmy_tracker_col)
  spr(9, 70, instr_y)
  pal()
end;

function draw_instrp_03()
  instr_y=18
  instr_text("the partly excavated levels are",6)
  instr_text("in the form of a grid made up of",6)
  instr_text("20 'boxes'. to uncover a 'box',",6)
  instr_text("move your team along the 4 sides",6)
  instr_text("of the box from each corner to",6)
  instr_text("the next.",6)
  instr_y+=3
  spr(44,44,instr_y)
  spr(45,60,instr_y)
  spr(46,76,instr_y)
  instr_y+=12
  instr_text("not all boxes need to be",6)
  instr_text("uncovered to enable you to go",6)
  instr_text("through the exit and into the",6)
  instr_text("next level...",6)
end

function draw_instrp_04()
  instr_y=18
  instr_text("each level contains:",6)
  instr_y+=6
  instr_text("10 treasure boxes",6)
  instr_text("6 empty boxes",6)
  instr_text("a royal mummy, a guardian mummy",6)
  instr_text("a key and a scroll.",6)
  instr_y+=3
  spr(38,28,instr_y)
  spr(39,44,instr_y)
  spr(23,60,instr_y)
  spr(21,76,instr_y)
  spr(22,92,instr_y)
  instr_y+=12
  instr_text("if you uncover the box holding",6)
  instr_text("the guardian mummy, it will dig",6)
  instr_text("its way out and pursue you",6)
  instr_y+=6
  instr_text("being caught by a guardian mummy",6)
  instr_text("kills one member of your team",6)
  instr_text("and the mummy, unless you have",6)
  instr_text("uncovered the scroll",6)
end

function draw_instrp_05()
  instr_y=18
  instr_text("the magic scroll allows you to",6)
  instr_text("be caught by a guardian, without",6)
  instr_text("any harm to your team",6)
  instr_y+=3
  spr(22,50,instr_y)
  spr(57,70,instr_y)
  instr_y+=12
  instr_text("the scroll works only on",6)
  instr_text("the level on which found",6)
  instr_text("it will only destroy 1 guardian",6)
  instr_y+=6
  instr_text("there are 2 ways to gain points:",6)
  instr_y+=6
  instr_text("uncovering the royal mummy",6)
  instr_text("and by uncovering treasure.",6)
  instr_y+=3
  spr(23,50,instr_y)
  spr(38,70,instr_y)
end

function draw_instrp_06()
  instr_y=18
  instr_text("when the boxes holding the key",6)
  instr_text("and the royal mummy have been",6)
  instr_text("uncovered, you will be able",6)
  instr_text("to leave the level",6)
  instr_y+=3
  spr(21,50,instr_y)
  spr(23,70,instr_y)
  instr_y+=12
  instr_text("remaining guardians will be",6)
  instr_text("able to follow you onto",6)
  instr_text("the next level.",6)
  instr_y+=6
  instr_text("after completing all 5 levels",6)
  instr_text("of a pyramid you will, when",6)
  instr_text("you leave the fifth level,",6)
  instr_text("move to level 1, of the",6)
  instr_text("next pyramid.",6)
end

function draw_instrp_07()
  instr_y=18
  instr_text("when you have completed a",6)
  instr_text("pyramid, your success will",6)
  instr_text("be rewarded either by",6)
  instr_text("bonus points or the arrival",6)
  instr_text("of an extra team member.",6)
  instr_y+=3
  spr(1,60,instr_y)
  instr_y+=12
  instr_text("the guardians in the next",6)
  instr_text("pyramid, having been warned",6)
  instr_text("by those you've escaped",6)
  instr_text("from, will be more alert, so it",6)
  instr_text("will pay to be more careful",6)
  instr_y+=3
  spr(42,44,instr_y)
  spr(43,60,instr_y)
  spr(41,76,instr_y)
end

function draw_instrp_08()
  instr_y=18
  instr_text("you can control your team using",6)
  instr_text("cursor keys.",6)
  instr_y+=6
  instr_text("the game has 4 skill levels",6)
  instr_text("these determine how 'clever'",6)
  instr_text("the guardians are at the.",6)
  instr_text("beginning of a game",6)
  instr_text("easy, normal, hard, and",6)
  instr_text("oh mummy",6)
  instr_y+=6
  instr_text("you may choose 3 speed levels",6)
  instr_text("from moderate to murderous",6)
end

function draw_instrp_09()
  instr_y=60
  instr_text("may ankh-sun-ahmun",6)
  instr_text("guide your steps ...",6)
end


__gfx__
0000000000ccc00000ccc000000000000000000000000000000000000000000000000000000aa000000aa0000000000011111111111111111111111111111111
0000000000a9190000a9190000000000000000000000000000000000000000000000000000aaaa0000aaaa000000000011111111111111111111111111111111
0070070000c9900000c9900000000000000000000000000000000000000000000000044400aaaa0000aaaa000000000011111111111111111111111111111111
0007700000acc00000acc000000000000000000000000000000000000000000004000400000aa000000aa0000000000011111111111111111111111111111111
0007700000caa90000caa900000000000000000000000000000000000000000004440000000aaaa0000aaaa00000000011111111111111111111111100cccc00
0070070000ccc00000ccc000000000000000000000000000000000000000000000000000000aa000000aa00000000000111111111111111100cccc0000cccc00
0000000009c00c00000c000000000000000000000000000000000000000000000000000000a00a00000a0000000000001111111100c00c0000c00c0000c00c00
00000000009009900009900000000000000000000000000000000000000000000000000000aa0aa0000aa000000000000cc00cc00cc00cc00cc00cc00cc00cc0
00000000000ccc00000ccc0000000000aaaaaaaacccccccccccccccccccccccc00000000000aa000000aa00000000000111111111111111111111111c00cc00c
0000000000919a0000919a0000000000aaaaaaaacccccccccccccccccccccccc0000000000aaaa0000aaaa00000000001111111111111111c0cccc0cc0cccc0c
0000000000099c0000099c0000000000aaaaaaaacccccaaccc0cc0cccacccaac0000000000aaaa0000aaaa000000000011111111c0cccc0cc0cccc0cc0cccc0c
00000000000cca00000cca0000000000aaaaaaaacaaaacacc10aa01ccaaaaaac00004440000aa000000aa000000000000c0cc0c00c0cc0c00c0cc0c00c0cc0c0
00000000009aac00009aac0000000000aaaaaaaaccaccaacc10aa01cc999999c004000400aaaa0000aaaa0000000000000cccc0000cccc0000cccc0000cccc00
00000000000ccc00000ccc0000000000aaaaaaaacacacccccc0cc0ccccaccacc44400000000aa000000aa0000000000000cccc0000cccc0000cccc0000cccc00
0000000000c00c900000c00000000000aaaaaaaacccccccccccccccccccccccc0000000000a00a000000a0000000000000c00c0000c00c0000c00c0000c00c00
00000000099009000009900000000000aaaaaaaacccccccccccccccccccccccc000000000aa0aa00000aa000000000000cc00cc00cc00cc00cc00cc00cc00cc0
0000000000cccc0000cccc0000cccc0044444444ffffffff999999991111111100000000a00aa00aa00aa00aa00aa00a999999997777777788888888bbbbbbbb
00000000009cc900009cc900009cc90044444444ffffffff99aaaa991111111100044000a0aaaa0aa0aaaa0aa0aaaa0a999999997777777788888888bbbbbbbb
0000000000999900009999000099990044444444ffffffff9a98c9a91111111100040000a0aaaa0aa0aaaa0aa0aaaa0a999999997777777788888888bbbbbbbb
000000000aacca9009accaa00aaccaa044444444ffffffffa090909a11111111000400000a0aa0a00a0aa0a00a0aa0a0999999997777777788888888bbbbbbbb
0000000009cccca00acccc9009cccc9044444444ffffffffa909090a111111110000000000aaaa0000aaaa0000aaaa00999999997777777788888888bbbbbbbb
0000000000cccc0000cccc0000cccc0044444444ffffffff9ac98ca9111111110000440000aaaa0000aaaa0000aaaa00999999997777777788888888bbbbbbbb
0000000000c0099009900c0000c00c0044444444ffffffff99aaaa99111111110000040000a00aa00aa00a0000a00a00999999997777777788888888bbbbbbbb
0000000009900000000009900990099044444444ffffffff9999999911111111000004000aa0000000000aa00aa00aa0999999997777777788888888bbbbbbbb
0000000000cccc0000cccc0000cccc000000000000000000d11dd11d0000000000400000a00aa00aa00aa00aa00aa00a3333333322222222ddddddddffffffff
0000000000acca0000acca0000acca000000000000000000d1dddd1d0000000000400000a0aaaa0aa0aaaa0aa0aaaa0a3333333322222222ddddddddffffffff
00000000009cc900009cc900009cc9000000000000000000d1dddd1d0000000000440000a0aaaa0aa0aaaa0aa0aaaa0a3333333322222222ddddddddffffffff
000000000acccc9009cccca00acccca000000000000000001d1dd1d100000000000000000a0aa0a00a0aa0a00a0aa0a03333333322222222ddddddddffffffff
0000000009cccca00acccc9009cccc90000000000000000011dddd11000000000000400000aaaa0000aaaa0000aaaa003333333322222222ddddddddffffffff
0000000000cccc0000cccc0000cccc00000000000000000011dddd11000000000000400000aaaa0000aaaa0000aaaa003333333322222222ddddddddffffffff
0000000000c0099009900c0000c00c00000000000000000011d11d11000000000004400000a00aa00aa00a0000a00a003333333322222222ddddddddffffffff
0000000009900000000009900990099000000000000000001dd11dd100000000000000000aa0000000000aa00aa00aa03333333322222222ddddddddffffffff
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555500000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000051111500000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000051111500000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000051111500000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005dddd500000000000000000000000000
0000000000000000000000000000005555555005500000555555555000000000005555555555555500000005555555555dddd500000000000000000000000000
000000000000000000000000000005ddddddd5dd500005ddddddddd50000000005dddddddddddddd5000005dddddddddddddd500000000000000000000000000
000000000000000000000000000005cccccccccc50005ccccccccccc500000005ccccccccccccccc500005ccccccccccccccc500000000000000000000000000
000000000000000000000000000005cccccccccc5005ccccccccccccc5000005cccccccccccccccc50005cccccccccccccccc500000000000000000000000000
000000000000000000000000000005cccccccccc5005cccccccccccccc50005ccccccccccccccccc5005ccccccccccccccccc500000000000000000000000000
000000000000000000000000000005cccccccccc505cccccccc555ccccc5005cccccccc555cccccc5005cccccccc555cccccc500000000000000000000000000
00000000000000000000000000000566666666555056666666500566666500566666665005666666505666666665005666666500000000000000000000000000
00000000000000000000000000000577777775000057777775000577777505777777750005777777505777777750005777117500000000000000000000000000
00000000000000000000000000000577117750000051177750000571177505777711500005777111505777777500005771111500000000000000000000000000
00000000000000000000000000000511111750000051111150000511111505111111500005111111505111111500005111111500000000000000000000000000
00000000000000000000000000000511111150000005111150005111111505111111500051111111505111111500051111111500000000000000000000000000
0000000000000000000000000000051111115000000511111555111eeeee05111111155511111111500511111155511111111500000000000000000000000000
000000000000000000000000000005222222500000005222222222eeeeee05222222222222222222500522222222222222222500000000000000000000000000
000000000000000000000000000005dddddd500000005dddddddeeeedee505ddddddddddddd5dddd50005dddddddddddddddd500000000000000000000000000
0000000000000000000000000000057777775000000005777777eee75ee000577777777775505777500005e77777777777777500000000000000000000000000
000000000000000000000000000005555555500000000055555eee550ee000055555555550eee555500e0eee555eeeee55555500000000000000000000000000
0000000000000000000000000000000000000ee00000eee000eeeeeeeeeeeee00ee00e000eeeeee0000eeeee00ee00ee00000000000000000000000000000000
000000000000000000000000000000000000eee333eeeeee33eeeeeeeeeeeee33ee3ee33ee333ee333ee33ee33e33ee000000000000000000000000000000000
000000000000000000000000000000000000eee33eeee3ee33eee33eee33eee3ee33ee3eee33eee333ee3ee33eeeee33ee000000000000000000000000000000
0000000000000000000000000000000000333eee3ee333ee3eee333ee333ee33ee3ee33ee333ee333ee33e33eeee333ee3000000000000000000000000000000
0000000000000000000000000000000003333eeeeee333eeeeee33eee3eeee3eee3eeeeee33eeeeeeee3eeee33eeeee333300000000000000000000000000000
00000000000000000000000000000000000000eeeee0eeeeeeee00eeeeeeeeeeeeeeee0eeeee0eeeee00eee0000eeee000000000000000000000000000000000
00000000000000000000000000000333333eeeeeeeeeee333ee333eeee33eee3eee3333333333333333333333333333333333330000000000000000000000000
000000000000000000000000000333333333eeee33eee333eee33333333333333333333333333333333333333333333333333333300000000000000000000000
000000000000000000000000003333333333333333333333ee333333333333333333333333333333333333333333333333333333330000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000033333333333333333333333333333333333333333333333333333333333333333333333333333333333333333000000000000000000
00000000000000000000333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333330000000000000000
00000000000000000003333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333000000000000000
__gff__
0000000000000000020000000101010100000000010101010200000001010101000000000101010102000000010101010000000000000100020000000103010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1414141414141414141414141414141440404040404040404040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1414141414141414141414141414141440000000400054004040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1414141414141414140000000000141440000000000054000040405b5c000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
14141414141414371414141414141414400000636465666768696a6b6c5d0040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
14141437373737373737373737371414404000737475767778797a7b7c6d0040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
14141437163715372737273724371414404000838485868788898a8b8c000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
14141437373737373737373737371414400092939495969798999a9b9c9d9e40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1414143724371537273727372737141440000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1414143737373737373737373737141440000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1414143724372437273717372437141440000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1414143737373737373737373737141440000040000000000000000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1414143724372437243724372437141440004040000000000000000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1414143737373737373737373737141440404040400000000000000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1414141414141414141414141414141440404040404040404040000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1414141414141414141414141414141440404040404040404040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1414141414141414141414141414141400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011300000c0300c0300e0300e0300f0300f0300f0300f0300e0300e0300e0300e0300c0300c0300c0300c0000c0300c0300e0300e0300f0300f03013030130300e0300e0300f0300f0300c0300c0300c03000000
011300000f0300f03011030110301303513035130351303513030130301403014030130301303011030110300e0300e0300f0300f030110351103511035110351103011030130301303011030110300f0300f030
011300000007500000070750000000070000000707507075000700000007075070050007000000070750707500075000000707500000000700000007075070750007500000070750000000070000000707507075
000100002e050290502805026050250502405023050230502305023050250502705028050290502b0502f0502e0502c0002c00000000000000000000000000000000000000000000000000000000000000000000
010f00002907729074290742907400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0120010011074100740f0740e0740d0740d0740d07400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0006000018050120500e0500b05007050040500205001050010500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 01034344
02 02034344

