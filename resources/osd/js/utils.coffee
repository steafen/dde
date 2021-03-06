#Copyright (c) 2011 ~ 2014 Deepin, Inc.
#              2011 ~ 2014 bluth
#
#encoding: utf-8
#Author:      bluth <yuanchenglu@linuxdeepin.com>
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

_b = document.body

DEBUG = false
FOCUS = false

setFocus = (focus)->
    FOCUS = focus
    FOCUS = true if DEBUG
    DCore.Osd.set_focus(FOCUS)

#MediaKey DBus
MEDIAKEY =
    obj: "com.deepin.daemon.KeyBinding"
    path: "/com/deepin/daemon/MediaKey"
    interface: "com.deepin.daemon.MediaKey"

TIME_HIDE = 1500
TIME_PRESS = 5
timeout_osdHide = null
DBusMediaKey = null
try
    DBusMediaKey = DCore.DBus.session_object(
        MEDIAKEY.obj,
        MEDIAKEY.path,
        MEDIAKEY.interface
    )
catch e
    echo "Error:-----DBusMediaKey:#{e}"
echo DBusMediaKey

allElsHide = ->
    els = _b.children
    for el in els
        if el.tagName = "DIV"
            el.style.display = "none"

osdHide = ->
    return if FOCUS
    echo "osdHide : #{timeout_osdHide}"
    
    allElsHide()
    DCore.Osd.hide()
    clearTimeout(timeout_osdHide)
    return
    
    #document.body.opacity = "1"
    #jQuery(document.body).animate(
    #    {opacity:'0';},200,"linear",->
    #        allElsHide()
    #        DCore.Osd.hide()
    #)

osdShow = ->
    allElsHide()
    DCore.Osd.show()
    document.body.opacity = "0"
    jQuery(document.body).animate({opacity:'1';},500)

osdHide()

click_time = 0
_b.addEventListener("click",(e)=>
    e.stopPropagation()
    echo click_time
    click_time++
    if click_time % 1 == 0
        click_time = 0
        DCore.Osd.hide()
)

_b.addEventListener("contextmenu",(e)=>
    e.preventDefault()
    e.stopPropagation()
)
        
setBodySize = (width,height)->
    _b.style.width = width
    _b.style.height = height

set_bg = (cls,imgName,prevImgName)->
    if prevImgName == imgName then return
    echo "set_bg: bgChanged from #{prevImgName} to #{imgName}"
    
    cls.bg1 = create_element("div","#{cls.id}_bg1",cls.element) if not cls.bg1?
    cls.bg2 = create_element("div","#{cls.id}_bg2",cls.element) if not cls.bg2?
    cls.bg1.style.position = "absolute"
    cls.bg2.style.position = "absolute"
    cls.bg1.style.width = "100%"
    cls.bg2.style.width = "100%"
    cls.bg1.style.height = "100%"
    cls.bg2.style.height = "100%"

    cls.bg1.style.backgroundImage = "url(img/#{prevImgName}.png)"
    cls.bg2.style.backgroundImage = "url(img/#{imgName}.png)"
    cls.bg1.style.display = "block"
    cls.bg2.style.display = "block"
    
    t = 500
    cls.bg1.style.opacity = "1.0"
    jQuery(cls.bg1).animate({opacity:'0';},t,"swing")
    cls.bg2.style.opacity = "0.0"
    jQuery(cls.bg2).animate({opacity:'1';},t,"swing")

showValue = (value,min,max,cls,id)->
    if value > max then value = max
    else if value < min then value = min
    else if value is null then value = min

    if not cls.bar?
        cls.bar = new Bar(id)
        cls.bar.setPosition(cls.element,"31px","20px","absolute")
        cls.bar.setSize("98px","6px")
        cls.bar.setColor("#FFF")
        cls.bar.showProgressNum(false)
        cls.bar.progressCreate()
    echo "showValue: setProgress-----#{value / max}---"
    cls.bar.setProgress(value / max) if cls.bar
