create_item = (info) ->
    w = null
    switch info.Type
        when "Application"
            w = new DesktopEntry info.Name, info.Icon, info.Exec, info.EntryPath
        when "File"
            w = new NormalFile info.Name, info.Icon, info.Exec, info.EntryPath
        when "Dir"
            w = new Folder info.Name, info.Icon, info.exec, info.EntryPath
        else
            echo "don't support type"

    div_grid.appendChild(w.element)
    return w


load_desktop_all_items = ->
    for info in DCore.Desktop.get_desktop_items()
        w = create_item(info)
        if w?
            move_to_anywhere(w)


reflesh_desktop_new_items = ->
    for info in DCore.Desktop.get_desktop_items()
        if not Widget.look_up(info.EntryPath)?
            w = create_item(info)
            if w?
                move_to_anywhere(w)
    return

reflesh_desktop_del_items = ->
    items= DCore.Desktop.get_desktop_items()
    for i, v of Widget.object_table
        exists = false
        for info in items
            if info.EntryPath == i
                exists = true
                break
        if exists == false
            v.destroy()
    return