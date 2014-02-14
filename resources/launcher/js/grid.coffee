#Copyright (c) 2011 ~ 2012 Deepin, Inc.
#              2011 ~ 2012 snyh
#
#Author:      snyh <snyh@snyh.org>
#Maintainer:  snyh <snyh@snyh.org>
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

grid = $('#grid')
grid.addEventListener("contextmenu", menuDelegate)

fn = (e)->
    offset = 0
    id = -2
    l = this.childNodes.length
    # TODO:
    # 1. category bar
    # 2. the last shown category's id
    # 3. top only mask when the scroll bar is almost on the # bottom.
    for i in [0...l]
        if this.childNodes[i].style.display == 'none'
            continue
        candidateId = this.childNodes[i].id
        if this.scrollTop - offset < 0
            # echo "less #{id} #{$("##{id}").firstChild.firstChild.textContent}"
            $("#grid").style.webkitMaskImage = "-webkit-linear-gradient(top, rgba(0,0,0,0), rgba(0,0,0,1) 5%, rgba(0,0,0,1) 90%, rgba(0,0,0,0.3), rgba(0,0,0,0))"
            categoryBar.showCategory(id.substr(Category.PREFIX.length))
            break
        else if this.scrollTop - offset == 0
            id = this.childNodes[i].id
            # echo "equal #{id} #{$("##{id}").firstChild.firstChild.textContent}"
            if id == "c-2"
                this.style.webkitMask = "none"
            else
                this.style.webkitMask = "-webkit-linear-gradient(top, rgba(0,0,0,1), rgba(0,0,0,1) 90%, rgba(0,0,0,0.3), rgba(0,0,0,0))"
            categoryBar.showCategory(id.substr(Category.PREFIX.length))
            break
        else
            id = candidateId
            offset += this.childNodes[i].clientHeight + CATEGORY_CONTENT_MARGIN


    return

$("#grid").addEventListener("scroll", fn)

###
update_items = (items) ->
    for id in items
        item_to_be_shown = grid.removeChild($("#"+id))
        grid.appendChild(item_to_be_shown)
    return items

_update_scroll_bar = (len) ->
    lang = _b.getAttribute('lang')
    if lang == 'en'
        category_width = 220
    else
        category_width = 180
    grid_width = window.screen.width - 20 - category_width
    lines = Math.ceil(ITEM_WIDTH * len / grid_width)

    grid_height = window.screen.height - 100
    if lines * ITEM_HEIGHT >= grid_height
        grid.style.overflowY = "scroll"
    else
        grid.style.overflowY = "hidden"

grid_show_items = (items) ->
    update_selected(null)

    hidden_icon_ids = hidden_icons.id_list()
    count = 0
    for i in items
        if i not in hidden_icon_ids
            count += 1
    _update_scroll_bar(count)

    for own key, value of applications
        if key not in items
            value.hide()

    count = 0
    for id in items
        group_num = parseInt(count++ / NUM_SHOWN_ONCE)
        setTimeout(applications[id].show, 4 + group_num)

    return  # some return like here will keep js converted by coffeescript returning stupid things

grid_load_category = (cat_id) ->
    grid_show_items(category_bar.items(cat_id))
    update_selected(null)


init_grid = ->
    # sort_category_info(sort_methods[sort_method])
    update_items(category_infos[CATEGORY_ID.ALL])
    grid_load_category(CATEGORY_ID.ALL)

show_grid_dom_child = ->
    c = grid.children
    i = 0
    while i < c.length
        echo "#{get_name_by_id(c[i].id)}"
        i = i + 1
###
