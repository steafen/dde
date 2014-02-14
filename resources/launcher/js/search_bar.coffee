#Copyright (c) 2011 ~  Deepin, Inc.
#              2013 ~ Lee Liqiang
#
#Author:      Lee Liqiang <liliqiang@linuxdeepin.com>
#Maintainer:  Lee Liqiang <liliqiang@linuxdeepin.com>
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


class SearchBar
    constructor:->
        @searchBar = $("#search")
        @key = $("#searchKey")
        DCore.signal_connect("im_commit", (info)->
            s_box.textContent += info.Content
        )
        @searchTimer = null

    hide: ->
        if @searchBar.style.visibility != 'hidden'
            @searchBar.style.visibility = 'hidden'

    show: ->
        if @searchBar.style.visibility != 'visible'
            @searchBar.style.visibility = 'visible'

    value: (t)->
        if t?
            @key.textContent = t
        else
            @key.textContent

    empty: ->
        @value() == ""

    clean:->
        @key.textContent = ""

    search: ->
        clearTimeout(@searchTimer)
        @searchTimer = setTimeout(=>
            ids = daemon.Search_sync(@value())
            # echo ids
            res = $("#searchResult")
            for i in [0...res.children.length]
                if res.children[i].style.display != 'none'
                    res.children[i].style.display = 'none'

            for i in [ids.length-1..0]
                if (item = $("#se_#{ids[i]}"))?
                    res.removeChild(item)
                    item.style.display = '-webkit-box'
                    res.insertBefore(item, res.firstChild)

            if $("#searchResult").style.display != 'block'
                switcher.hideCategory()
                $("#grid").style.display = 'none'
                $("#searchResult").style.display = 'block'
        , 200)
