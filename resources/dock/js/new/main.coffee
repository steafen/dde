# DCore.signal_connect("active_window_changed", (info)->)
# DCore.signal_connect("launcher_added", (info) ->)
# DCore.signal_connect("dock_request", (info) ->)
# DCore.signal_connect("launcher_removed", (info) ->)
# DCore.signal_connect("task_updated", (info) ->)
# DCore.signal_connect("dock_hidden", ->)
# DCore.signal_connect("task_removed", (info) ->)
# DCore.signal_connect("close_window", (info)->)
# DCore.signal_connect("active_window", (info)->)
DCore.signal_connect("in_mini_mode", ->)
DCore.signal_connect("in_normal_mode", ->)
DCore.signal_connect("message_notify", (info)->)

DCore.signal_connect("embed_window_configure_changed", (info)->console.log(info))
DCore.signal_connect("embed_window_destroyed", (info)->console.log(info))
DCore.signal_connect("embed_window_enter", (info)->console.log(info))
DCore.signal_connect("embed_window_leave", (info)->console.log(info))

document.body.addEventListener("contextmenu", (e)->
    e.preventDefault()
)
document.body.addEventListener("drop", (e)->
    console.log("drop on body")
    s_id = e.dataTransfer.getData(DEEPIN_ITEM_ID)
    s_widget = Widget.look_up(s_id)
    if s_widget and s_widget.isNormal()
        t = app_list.element.removeChild(s_widget.element)
        calc_app_item_size()

        t.style.position = "fixed"
        t.style.left = (e.x + s_widget.element.clientWidth/2)+ "px"
        t.style.top = (e.y + s_widget.element.clientHeight/2)+ "px"
        document.body.appendChild(t)
        s_widget.destroyWidthAnimation()
        dockedAppManager.Undock(s_id)
)
document.body.addEventListener("dragenter", (e)->
    clearTimeout(cancelInsertTimer)
)
document.body.addEventListener("dragover", (e)->
    clearTimeout(cancelInsertTimer)
    app_list.hide_indicator()
    console.log("dragover on body")
    s_id = e.dataTransfer.getData(DEEPIN_ITEM_ID)
    if Widget.look_up(s_id)?.isNormal()
        e.preventDefault()
)

settings = new Setting()

show_desktop = new ShowDesktop()

panel = new Panel("panel")
panel.draw()

app_list = new AppList("app_list")

$DBus = {}

EntryManager =
    name:"com.deepin.daemon.Dock"
    path:"/dde/dock/EntryManager"
    interface:"dde.dock.EntryManager"
entryManager = get_dbus('session', EntryManager)

trayIcon = DCore.get_theme_icon("deepin-systray", 48) || NOT_FOUND_ICON
systemTray = null
# freedesktop = get_dbus("session", "org.freedesktop.DBus")
# freedesktop.connect("NameOwnerChanged", (name, oldName, newName)->
#     if newName != "" && name == "com.deepin.dde.TrayManager" && not systemTray
#         systemTray = new SystemTray("system-tray", trayIcon, "")
# )
entryManager.connect("TrayInited",->
    if not systemTray
        systemTray = new SystemTray("system-tray", trayIcon, "")
)

entryManager.connect("Added", (path)->
    d = get_dbus("session", itemDBus(path))
    console.log("try to Add #{d.Id}, #{TRASH_ID}")
    if d.Id == TRASH_ID
        t = Widget.look_up(d.Id)
        t.core = d
        t.show_indicator()
        return

    if Widget.look_up(d.Id)
        return

    console.log("Added #{path}")
    createItem(d)
    # console.log("added done")
    calc_app_item_size()
    if systemTray?.isShowing
        systemTray.updateTrayIcon()

    setTimeout(->
        calc_app_item_size()
        if systemTray?.isShowing
            systemTray.updateTrayIcon()
    , 100)
)

entryManager.connect("Removed", (id)->
    # TODO: change id to the real id
    console.log("Removed #{id}")
    if id == TRASH_ID
        t = Widget.look_up(id)
        t.core = null
        t.hide_indicator()
        return
    deleteItem(id)
    calc_app_item_size()
    systemTray?.updateTrayIcon()
)

entries = entryManager.Entries
for entry in entries
    console.log(entry)
    d = get_dbus("session", itemDBus(entry))
    console.log("init add: #{d.Id}")
    if !Widget.look_up(d.Id)
        createItem(d)

initDockedAppPosition()

try
    icon_launcher = DCore.get_theme_icon("start-here", 48)

show_launcher = new LauncherItem("show_launcher", icon_launcher, _("Launcher"))
# clock = create_clock(DCore.Dock.clock_type())
trash = new Trash(TRASH_ID, Trash.get_icon(DCore.DEntry.get_trash_count()), _("Trash"))
show_desktop = new ShowDesktop()

DCore.Dock.emit_webview_ok()
DCore.Dock.test()

setTimeout(->
    IN_INIT = false
    try
        if not systemTray
            systemTray = new SystemTray("system-tray", trayIcon, "")
    catch
        systemTray.destroy()
        systemTray = null

    new Time("time", "js/plugins/time/img/time.png", "")
    calc_app_item_size()
    # apps are moved up, so add 8
    DCore.Dock.change_workarea_height(ITEM_HEIGHT * ICON_SCALE + 8)
, 100)
