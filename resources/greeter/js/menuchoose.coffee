#Copyright (c) 2011 ~ 2012 Deepin, Inc.
#              2011 ~ 2012 yilang
#
#Author:      bluth <yuanchenglu@linuxdeepin.com>
#             LongWei <yilang2007lw@gmail.com>
#                     <snyh@snyh.org>
#Maintainer:  bluth <yuanchenglu@linuxdeepin.com>
#
#This program is free software; you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation; either version 3 of the License, or
#(at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program; if not, see <http://www.gnu.org/licenses/>.

class MenuChoose extends Widget
    choose_num = -1
    select_state_confirm = false
    frame_click = true
    time_animation = 500

    constructor: (@id)->
        super
        @current = @id
        
        @option = []
        @option_text = []
        @img_url_normal = []
        @img_url_hover = []
        @img_url_click = []

        @opt = []
        @opt_img = []
        @opt_text = []
        
        document.body.appendChild(@element)
        @element.style.display = "none"

    show:->
        apply_animation($("#div_users"),"hide_animation","200")
        $("#div_users").addEventListener("webkitAnimationEnd",@animationEnd_div_users_hide ,false)

    hide:->
        for tmp ,i in @option
            @opt_text[i].style.display = "block"
            apply_animation(@opt_text[i],"hide_animation","200")
        @animationEnd_opt_text_hide()
        #@opt_text[0].addEventListener("webkitAnimationEnd",@animationEnd_opt_text_hide,false)
    
    animationEnd_div_users_hide:=>
        $("#div_users").style.display = "none" # set it in css
        if is_greeter
            $(".prevuserinfo").style.display = "none"
            $(".nextuserinfo").style.display = "none"
        
       
        @element.style.display = "block"
        @setmaxbutton_in_oneline(4)
        for tmp ,i in @option
            @opt_text[i].style.display = "none"
            apply_animation(@opt_img[i],"opt_img_scale_large",time_animation)
            #apply_animation(@opt_img[i],"opt_img_show_move",time_animation - i * 50)
        apply_animation(@element,"menu_show_move",time_animation)
        @opt_img[0].addEventListener("webkitAnimationEnd",@animationEnd_opt_img_large,false)
        
        $("#div_users").removeEventListener("webkitAnimationEnd",@animationEnd_div_users_hide,false)
    
    animationEnd_menu_hide:=>
        echo "animationEnd_menu_hide"
        @element.style.display = "none" # set it in css
        
        $("#div_users").style.display = "block" # set it in css
        apply_animation($("#div_users"),"show_animation","200")
        if is_greeter
            $(".prevuserinfo").style.display = "block"
            $(".nextuserinfo").style.display = "block"
        
        @element.removeEventListener("webkitAnimationEnd",@animationEnd_menu_hide,false)
    
    animationEnd_opt_text_hide:=>
        echo "animationEnd_menu_hide"
        for tmp ,i in @option
            @opt_text[i].style.display = "none"
            apply_animation(@opt_img[i],"opt_img_scale_small",time_animation)
            #apply_animation(@opt_img[i],"opt_img_hide_move",time_animation - i * 50)
        apply_animation(@element,"menu_hide_move",time_animation)
        
        @element.addEventListener("webkitAnimationEnd",@animationEnd_menu_hide ,false)
        @opt_text[0].removeEventListener("webkitAnimationEnd",@animationEnd_opt_text_hide,false)

    
    animationEnd_opt_img_large:=>
        for tmp ,i in @option
            @opt_text[i].style.display = "block"
            apply_animation(@opt_text[i],"show_animation","200")
        @opt_img[@opt_img.length - 1].removeEventListener("webkitAnimationEnd",@animationEnd_opt_img_large,false)

    insert: (id, title, img_normal,img_hover,img_click)->
        @option.push(id)
        @option_text.push(title)
        @img_url_normal.push(img_normal)
        @img_url_hover.push(img_hover)
        @img_url_click.push(img_click)
    
    body_click_to_hide:->
        document.body.addEventListener("click",(e)=>
            e.stopPropagation()
            if !frame_click and @element.style.display isnt "none"
                @hide()
                $(".password").focus()
            else
                frame_click = false
        )
 

    frame_build:(id,title,img)->
        @frame = create_element("div", "frame", @element)
        @button = create_element("div","button",@frame)
       
        @frame.addEventListener("click",(e)->
            e.stopPropagation()
            frame_click = true
        )
        @body_click_to_hide()

        for tmp ,i in @option
            @opt[i] = create_element("div","opt",@button)
            @opt[i].style.backgroundColor = "rgba(255,255,255,0.0)"
            @opt[i].style.border = "1px solid rgba(255,255,255,0.0)"
            @opt[i].value = i
            
            @opt_img[i] = create_img("opt_img",@img_url_normal[i],@opt[i])
            @opt_text[i] = create_element("div","opt_text",@opt[i])
            @opt_text[i].textContent = @option_text[i]
            
            that = @
            #hover
            @opt[i].addEventListener("mouseover",->
                i = this.value
                choose_num = i
                that.opt_img[i].src = that.img_url_hover[i]
                that.hover_state(i)
            )
            
            #normal
            @opt[i].addEventListener("mouseout",->
                i = this.value
                that.opt_img[i].src = that.img_url_normal[i]
            )

            #click
            @opt[i].addEventListener("mousedown",->
                i = this.value
                that.opt_img[i].src = that.img_url_click[i]
            )
            @opt[i].addEventListener("click",(e)->
                e.stopPropagation()
                i = this.value
                frame_click = true
                that.opt_img[i].src = that.img_url_click[i]
                that.current = that.option[i]
                that.fade(i)
            )
    
    setmaxbutton_in_oneline:(maxnum)->
        j = 0
        for tmp ,i in @opt
            if i%maxnum == 0
                @opt[i].style.left = 0
                if i > 0
                    j++
                    for k in [0...maxnum]
                        if i + k > @opt.length - 1 then break
                        @opt[i + k].style.top = @opt[0].offsetTop + @opt[0].offsetHeight * j
            else
                @opt[i].style.left = @opt[i- 1].offsetLeft + @opt[i - 1].offsetWidth

 

    set_callback: (@cb)->

       
    fade:(i)->
        echo "--------------fade:#{@option[i]}---------------"
        @hide()
        @cb(@option[i], @option_text[i])
    
    hover_state:(i)->
        choose_num = i
        if select_state_confirm then @select_state(i)
        for tmp,j in @opt_img
            if j == i then tmp.src = @img_url_hover[i]
            else tmp.src = @img_url_normal[j]
   
    select_state:(i)->
        select_state_confirm = true
        choose_num = i
        for tmp,j in @opt
            if j == i
                tmp.style.backgroundColor = "rgba(255,255,255,0.1)"
                tmp.style.border = "1px solid rgba(255,255,255,0.15)"
                tmp.style.borderRadius = "4px"
            else
                tmp.style.backgroundColor = "rgba(255,255,255,0.0)"
                tmp.style.border = "1px solid rgba(255,255,255,0.0)"
                tmp.style.borderRadius = null

    
    keydown:(e)->
        switch e.which
            when LEFT_ARROW
                choose_num--
                if choose_num == -1 then choose_num = @opt.length - 1
                @select_state(choose_num)
            when RIGHT_ARROW
                choose_num++
                if choose_num == @opt.length then choose_num = 0
                @select_state(choose_num)
            when ENTER_KEY
                i = choose_num
                @fade(i)
            when ESC_KEY
                destory_all()


class ComboBox extends Widget
    constructor: (@id, @on_click_cb) ->
        super
        @current_img = create_img("current_img", "", @element)
        
        if is_greeter
            de_current_id = localStorage.getItem("de_current_id")
            echo "-------------de_current_id:#{de_current_id}"
            if not de_current_id?
                echo "not de_current_id"
                de_current_id = DCore.Greeter.get_default_session() if is_greeter
                if de_current_id is null then de_current_id = "deepin"
                localStorage.setItem("de_current_id",de_current_id)
        else
            de_current_id = "shutdown"
        @menu = new MenuChoose("#{@id}_menuchoose")
        @menu.set_callback(@on_click_cb)

    insert: (id, title, img_normal,img_hover,img_click)->
        @menu.insert(id, title, img_normal,img_hover,img_click)
    
    frame_build:->
        @menu.frame_build()

    insert_noimg: (id, title)->
        @menu.insert_noimg(id, title)

    do_click: (e)->
        e.stopPropagation()
        if is_greeter
            if @menu.id is "power_menuchoose"
                $("#desktop_menuchoose").style.display = "none"
            else if @menu.id is "desktop_menuchoose"
             $("#power_menuchoose").style.display = "none"
        if @menu.element.style.display isnt "none"
            @menu.hide()
        else
            @menu.show()
    
    get_current: ->
        de_current_id = localStorage.getItem("de_current_id")
        @menu.current = de_current_id
        return @menu.current

    set_current: (id)->
        try
            echo "set_current(id) :---------#{id}----------------"
            if @id is "desktop"
                current_img_src = "images/desktopmenu/current/#{id}.png"
            else if @id is "power"
                current_img_src = "images/powermenu/#{id}.png"
            @current_img.src = current_img_src
        catch error
            echo "set_current(#{id}) error:#{error}"
            if @id is "desktop"
                current_img_error = "images/desktopmenu/current/unkown.png"
            else if @id is "power"
                current_img_error = "images/powermenu/powermenu.png"
            @current_img.src = current_img_error
        localStorage.setItem("de_current_id",id)
        @menu.current = id
        return id
