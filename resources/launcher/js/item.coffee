#Copyright (c) 2011 ~ 2013 Deepin, Inc.
#              2013 ~ 2013 Li Liqiang
#
#Author:      Li Liqiang <liliqiang@linuxdeepin.com>
#Maintainer:  Li Liqiang <liliqiang@linuxdeepin.com>
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


try
    s_dock = DCore.DBus.session("com.deepin.dde.dock")
catch error
    s_dock = null


class Item extends Widget
    @autostart_flag: null
    @hover_item_id: null
    @clean_hover_temp: false
    @display_temp: false
    constructor: (@id, @name, @path, @icon)->
        super
        @element.removeAttribute("id")
        @element.setAttribute("appid", @id)
        @basename = get_path_name(@path) + ".desktop"
        @isAutostart = false
        @status = SOFTWARE_STATE.IDLE
        @displayMode = 'display'

        @load_image()
        @itemName = create_element("div", "item_name", @element)
        @itemName.innerText = @name
        @element.draggable = true
        # @try_set_title(@element, @name, 80)
        # @element.setAttribute("title", @name)

    @updateHorizontalMargin:->
        containerWidth = $("#container").clientWidth
        # echo "containerWidth:#{containerWidth}"
        Item.itemNumPerLine = Math.floor(containerWidth / ITEM_WIDTH)
        # echo "itemNumPerLine: #{Item.itemNumPerLine}"
        Item.horizontalMargin =  (containerWidth - Item.itemNumPerLine * ITEM_WIDTH) / 2 / Item.itemNumPerLine
        # echo "horizontalMargin: #{Item.horizontalMargin}"
        for own id, info of applications
            info.element.style.marginLeft = "#{Item.horizontalMargin}px"
            info.element.style.marginRight = "#{Item.horizontalMargin}px"
            if info.favorElement
                info.favorElement.style.marginLeft = "#{Item.horizontalMargin}px"
                info.favorElement.style.marginRight = "#{Item.horizontalMargin}px"

    try_set_title: (el, text, width)->
        setTimeout(->
            height = calc_text_size(text, width)
            if height > 38
                el.setAttribute('title', text)
        , 200)

    destroy: ->
        switch @constructor.name
            when "Item"
                categoryList.removeItem(@id)
            when "SearchItem"
                $("#searchResult").removeChild(@element)
            when "FavorItem"
                categoryList.favor.removeItem(@id)
        delete Widget.object_table[@id]

    get_img: ->
        im = DCore.get_theme_icon(@icon, 48)
        if im == null
            @icon = get_path_name(@path)

        im = DCore.get_theme_icon(@icon, 48)
        if im == null
            im = DCore.get_theme_icon(INVALID_IMG, ITEM_IMG_SIZE)

        im

    update: (info)->
        # TODO: update category infos
        # update it.
        if @name != info?.name
            @name = info.name
            @itemName.innerText = @name

        if @path != info?.path
            @path = info.path

        if @basename != info?.basename
            @basename = info.basename

        if @icon != info?.icon
            @icon = info.icon
            im = @get_img()
            @img.src = im

        if @isAutostart != info?.isAutostart
            @toggle_autostart()

        if @status != info?.status
            @status = info.status

        if @displayMode != info?.displayMode
            @toggle_icon()
            # @displayMode = info.displayMode

    load_image: ->
        im = @get_img()
        @img = create_img("", im, @element)
        @img.onload = (e) =>
            if @img.width == @img.height
                @img.className = 'square_img'
            else if @img.width > @img.height
                @img.className = 'hbar_img'
                new_height = ITEM_IMG_SIZE * @img.height / @img.width
                grap = (ITEM_IMG_SIZE - Math.floor(new_height)) / 2
                @img.style.padding = "#{grap}px 0px"
            else
                @img.className = 'vbar_img'
        @img.onerror = (e) =>
            src = DCore.get_theme_icon('invalid-dock_app', ITEM_IMG_SIZE)
            if src != @img.src
                @img.src = src

    on_click: (e)->
        e = e.originalEvent
        e?.stopPropagation()
        @element.style.cursor = "wait"
        startManager.Launch(@basename)
        Item.hover_item_id = @id
        @element.style.cursor = "auto"
        exit_launcher()

    on_dragstart: (e)=>
        e = e.originalEvent
        e.dataTransfer.setData("text/uri-list", "file://#{escape(@path)}")
        e.dataTransfer.setDragImage(@img, 20, 20)
        e.dataTransfer.effectAllowed = "all"

    createMenu:->
        DCore.Launcher.force_show(true)
        @menu = null
        @menu = new Menu(
            DEEPIN_MENU_TYPE.NORMAL,
            new MenuItem(1, _("_Open")),
            new MenuSeparator(),
            new MenuItem(2, ITEM_HIDDEN_ICON_MESSAGE[@displayMode]),
            # new MenuItem(7, FAVOR_MESSAGE[@isFavof]),
            new MenuSeparator(),
            new MenuItem(3, _("Send to d_esktop")).setActive(
                not daemon.IsOnDesktop_sync(@path)
            ),
            new MenuItem(4, _("Send to do_ck")).setActive(s_dock != null),
            new MenuSeparator(),
            new MenuItem(5, AUTOSTART_MESSAGE[@isAutostart]),
            new MenuSeparator(),
            new MenuItem(6, _("_Uninstall"))
        )

        if DCore.DEntry.internal()
            @menu.addSeparator().append(
                new MenuItem(100, "report this bad icon")
            )

    on_rightclick: (e)->
        e.preventDefault()
        e.stopPropagation()
        @createMenu()

        # echo @menu
        # return
        @menu.dbus.connect("MenuUnregistered", -> DCore.Launcher.force_show(false))
        @menu.addListener(@on_itemselected).showMenu(e.screenX, e.screenY)

    on_itemselected: (id)=>
        id = parseInt(id)
        switch id
            when 1
                startManager.Launch(@basename)
                # exit_launcher()
            when 2 then @toggle_icon()
            when 3 then daemon.SendToDesktop(@path)
            when 4 then s_dock?.RequestDock_sync(escape(@path))
            when 5 then @toggle_autostart()
            when 6
                if confirm("This operation may lead to uninstalling other corresponding softwares. Are you sure to uninstall this Item?", "Launcher")
                    @status = SOFTWARE_STATE.UNINSTALLING
                    @hide()
                    uninstalling_apps[@id] = @
                    echo 'start uninstall'
                    uninstall(item:@, purge:true)
            when 100 then DCore.DEntry.report_bad_icon(@path)  # internal
        DCore.Launcher.force_show(false)

    hide_icon: (e)=>
        @displayMode = "hidden"
        applications[@id].setDisplayMode("hidden").notify()
        if HIDE_ICON_CLASS not in @element.classList
            @add_css_class(HIDE_ICON_CLASS, @element)
        if not Item.display_temp and not is_show_hidden_icons
            @element.style.display = 'none'
            Item.display_temp = false
         if !hiddenIcons.contains(@id)
             # echo 'save'
            hiddenIcons.add(@id, @).save()
        categoryBar.hideEmptyCategories()
        categoryList.hideEmptyCategories()
        hidden_icons_num = hiddenIcons.number()
        if hidden_icons_num == 0
            Item.display_temp = false

    display_icon: (e)=>
        @displayMode = "display"
        applications[@id].setDisplayMode("display").notify()
        @element.style.display = '-webkit-box'
        if HIDE_ICON_CLASS in @element.classList
            @remove_css_class(HIDE_ICON_CLASS, @element)
        hidden_icons_num = hiddenIcons.remove(@id).save().number()
        categoryList.showNonemptyCategories()
        if hidden_icons_num == 0
            is_show_hidden_icons = false
            _show_hidden_icons(is_show_hidden_icons)

    display_icon_temp: ->
        @element.style.display = '-webkit-box'
        Item.display_temp = true
        categoryList.showNonemptyCategories()

    toggle_icon: ->
        if @displayMode == 'display'
            @hide_icon()
        else
            @display_icon()

    add_to_autostart: ->
        # echo @basename
        if startManager.AddAutostart_sync(@path)
            # echo 'add success'
            @isAutostart = true
            # if @id.indexOf("_") != -1
            #     applications[@id.substr(3)].setAutostart(true).notify()
            # else
            #     applications[@id].setAutostart(true).notify()
            Item.autostart_flag ?= DCore.get_theme_icon(AUTOSTART_ICON.NAME,
                AUTOSTART_ICON.SIZE)
            last = @element.lastChild
            if last.tagName != 'IMG'
                create_img("autostart_flag", Item.autostart_flag, @element)
            last.style.visibility = 'visible'

    remove_from_autostart: ->
        if startManager.RemoveAutostart_sync(@path)
            @isAutostart = false
            # applications[@id].setAutostart(false).notify()
            last = @element.lastChild
            if last.tagName == 'IMG'
                last.style.visibility = 'hidden'

    toggle_autostart: ->
        if @isAutostart
            @remove_from_autostart()
        else
            @add_to_autostart()

    hide: ->
        @element.style.display = "none"

    # use '->', Item.display_temp and @displayMode will be undifined when
    # this function is pass to some other functions like setTimeout
    show: =>
        if (Item.display_temp or @displayMode == 'display') and @status == SOFTWARE_STATE.IDLE
            @element.style.display = "-webkit-box"

    is_shown: ->
        @element.style.display != "none"

    # just working for categories, not searching and favor.
    focusedCategory:->
        cid = parseInt(@element.parentNode.parentNode.getAttribute("catid"))
        categoryList.category(cid)

    select: ->
        @element.classList.add("item_selected")

    unselect: ->
        @element.classList.remove("item_selected")

    next_shown: ->
        appid = @element.nextElementSibling?.getAttribute("appid")
        if appid
            n = Widget.look_up(appid)
            if n.is_shown() then n else n.next_shown()
        else
            null

    prev_shown: ->
        appid = @element.previousElementSibling?.getAttribute("appid")
        if appid
            n = Widget.look_up(appid)
            if n.is_shown() then n else n.prev_shown()
        else
            null

    scroll_to_view: (p)->
        if !@inView(p)
            rect = @element.getBoundingClientRect()
            prect = p.getBoundingClientRect()
            if rect.top < prect.top
                offset = rect.top - prect.top
                p.scrollTop += offset - 20 # for search
            else if rect.bottom > prect.bottom
                offset = rect.bottom - prect.bottom
                p.scrollTop += offset + 20 # for search
        # @element.scrollIntoViewIfNeeded()

    inView:(p)->
        rect = @element.getBoundingClientRect()
        prect = p.getBoundingClientRect()
        rect.top > prect.top && rect.bottom < prect.bottom

    isSameLineAux: (el)->
        @element.getBoundingClientRect().top == el.getBoundingClientRect().top

    isSameLine: (o)->
        @isSameLineAux(o.element)

    isLastLine: (o)->
        el = @element
        while (el = el.nextElementSibling)?
            if not @isSameLineAux(el)
                return false
        return true

    isFirstLine: (o)->
        el = @element
        while (el = el.previousElementSibling)?
            if not @isSameLineAux(el)
                return false
        return true

    indexOnLine: ->
        el = @element
        i = 0
        while (el = el.previousElementSibling)?
            if !@isSameLineAux(el)
                break
            i += 1
        i

    on_mouseover: (e)=>
        # this event is a wrap, use e.originalEvent to get the original event
        target = e.target
        Item.hover_item_id = @id
        if not Item.clean_hover_temp
            # not use @select() for storing status.
            target.style.background = "rgba(255, 255, 255, 0.15)"
            target.style.border = "1px rgba(255, 255, 255, 0.25) solid"
            target.style.borderRadius = "4px"

    on_mouseout: (e)=>
        target = e.target
        target.style.border = "1px rgba(255, 255, 255, 0.0) solid"
        target.style.background = ""
        target.style.borderRadius = ""


class SearchItem extends Item
    constructor: (@id, @name, @path, @icon)->
        super(@id, @name, @path, @icon)
        @element.classList.add("Item")

    # destroy: ->
    #     $("#searchResult").removeChild(@element)
    #     super

    @updateHorizontalMargin: ->
        containerWidth = $("#container").clientWidth
        # echo "containerWidth:#{containerWidth}"
        SearchItem.itemNumPerLine = Math.floor(containerWidth / ITEM_WIDTH)
        # echo "itemNumPerLine: #{Item.itemNumPerLine}"
        SearchItem.horizontalMargin =  (containerWidth - SearchItem.itemNumPerLine * ITEM_WIDTH) / 2 / SearchItem.itemNumPerLine
        # echo "horizontalMargin: #{Item.horizontalMargin}"
        for own id, info of applications
            if !(i = Widget.look_up("se_#{id}"))
                continue
            i.element.style.marginLeft = "#{SearchItem.horizontalMargin}px"
            i.element.style.marginRight = "#{SearchItem.horizontalMargin}px"
            if i.favorElement
                i.favorElement.style.marginLeft = "#{SearchItem.horizontalMargin}px"
                i.favorElement.style.marginRight = "#{SearchItem.horizontalMargin}px"


class FavorItem extends Item
    constructor: (@id, @name, @path, @icon)->
        super(@id, @name, @path, @icon)
        @element.classList.add("Item")

    # destroy: ->
    #     categoryList.favor.removeItem(@id)
    #     super

    @updateHorizontalMargin: ->
        containerWidth = $("#container").clientWidth
        # echo "containerWidth:#{containerWidth}"
        Item.itemNumPerLine = Math.floor(containerWidth / ITEM_WIDTH)
        # echo "itemNumPerLine: #{Item.itemNumPerLine}"
        Item.horizontalMargin =  (containerWidth - Item.itemNumPerLine * ITEM_WIDTH) / 2 / Item.itemNumPerLine
        # echo "horizontalMargin: #{Item.horizontalMargin}"
        for own id, info of applications
            info.element.style.marginLeft = "#{Item.horizontalMargin}px"
            info.element.style.marginRight = "#{Item.horizontalMargin}px"
            if info.favorElement
                info.favorElement.style.marginLeft = "#{Item.horizontalMargin}px"
                info.favorElement.style.marginRight = "#{Item.horizontalMargin}px"


createItem=->
