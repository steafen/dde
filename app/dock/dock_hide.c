#include "dock_hide.h"
#include "region.h"
#include "dock_config.h"
#include "tasklist.h"
#include <gtk/gtk.h>
#include <gdk/gdkx.h>

extern int _dock_height;
extern void _change_workarea_height(int height);
extern GdkWindow* DOCK_GDK_WINDOW();

#define GUARD_WINDOW_HEIGHT 1

enum Event {
    TriggerShow,
    TriggerHide,
    ShowNow,
    HideNow,
};
static void handle_event(enum Event ev);
static void _cancel_detect_hide_mode();

enum State {
    StateShow,
    StateShowing,
    StateHidden,
    StateHidding,
} CURRENT_STATE = StateShow;

gboolean dock_is_hidden()
{
    if (CURRENT_STATE == StateHidding)
        return TRUE;
    else
        return FALSE;
}

static void set_state(enum State new_state)
{
    /*char* StateStr[] = { "StateShow", "StateShowing", "StateHidden", "StateHidding"};*/
    /*printf("from %s to %s\n", StateStr[CURRENT_STATE], StateStr[new_state]);*/
    CURRENT_STATE = new_state;
}


extern int _screen_width;
static void enter_show()
{
    g_assert(CURRENT_STATE != StateShow);

    set_state(StateShow);
    _change_workarea_height(_dock_height);
    gdk_window_move(DOCK_GDK_WINDOW(), 0, 0);
}
static void enter_hide()
{
    g_assert(CURRENT_STATE != StateHidden);

    set_state(StateHidden);
    _change_workarea_height(0);
    gdk_window_move(DOCK_GDK_WINDOW(), 0, _dock_height-3);
}

#define SHOW_HIDE_ANIMATION_STEP 10
#define SHOW_HIDE_ANIMATION_INTERVAL 40
static gboolean do_hide_animation(int data);
static gboolean do_show_animation(int data);
static guint _animation_show_id = 0;
static guint _animation_hide_id = 0;

static void _cancel_animation()
{
    if (_animation_show_id != 0) {
        g_source_remove(_animation_show_id);
        _animation_show_id = 0;
    }
}
static void enter_hidding()
{
    set_state(StateHidding);
    _cancel_animation();
    do_hide_animation(_dock_height);
}
static void enter_showing()
{
    set_state(StateShowing);
    _cancel_animation();
    do_show_animation(0);
}

static void handle_event(enum Event ev)
{
    switch (CURRENT_STATE) {
        case StateShow: {
                            switch (ev) {
                                case TriggerShow:
                                    break;
                                case TriggerHide:
                                    enter_hidding(); break;
                                case ShowNow:
                                    break;
                                case HideNow:
                                    enter_hide(); break;
                                default:
                                    g_assert_not_reached();
                            }
                            break;
                        }
        case StateShowing: {
                               switch (ev) {
                                   case TriggerShow:
                                       break;
                                   case TriggerHide:
                                       enter_hidding(); break;
                                   case ShowNow:
                                       enter_show(); break;
                                   case HideNow:
                                       enter_hide(); break;
                                   default:
                                       g_assert_not_reached();
                               }
                               break;
                           }
        case StateHidden: {
                              switch (ev) {
                                  case TriggerShow:
                                      enter_showing(); break;
                                  case TriggerHide:
                                      break;
                                  case ShowNow:
                                      enter_show(); break;
                                  case HideNow:
                                      break;
                                  default:
                                      g_assert_not_reached();
                              }
                              break;
                          }
        case StateHidding: {
                               switch (ev) {
                                   case TriggerShow:
                                       enter_showing(); break;
                                   case TriggerHide:
                                       break;
                                   case ShowNow:
                                       enter_show(); break;
                                   case HideNow:
                                       enter_hide(); break;
                                   default:
                                       g_assert_not_reached();
                               }
                               break;
                           }
    };
}



static gboolean do_show_animation(int current_height)
{
    if (CURRENT_STATE != StateShowing) return FALSE;

    if (current_height <= _dock_height) {
        gdk_window_move(DOCK_GDK_WINDOW(), 0, _dock_height - current_height);
        _change_workarea_height(current_height);
        _animation_show_id = g_timeout_add(SHOW_HIDE_ANIMATION_INTERVAL, (GSourceFunc)do_show_animation,
                GINT_TO_POINTER(current_height + SHOW_HIDE_ANIMATION_STEP));
    } else {
        handle_event(ShowNow);
    }
    return FALSE;
}

static gboolean do_hide_animation(int current_height)
{
    if (CURRENT_STATE != StateHidding) return FALSE;

    if (current_height >= 0) {
        gdk_window_move(DOCK_GDK_WINDOW(), 0, _dock_height - current_height);
        _change_workarea_height(current_height);
        _animation_hide_id = g_timeout_add(SHOW_HIDE_ANIMATION_INTERVAL, (GSourceFunc)do_hide_animation,
                GINT_TO_POINTER(current_height - SHOW_HIDE_ANIMATION_STEP));
    } else {
        handle_event(HideNow);
    }
    return FALSE;
}


static gboolean do_hide_dock()
{
    handle_event(TriggerHide);
    return FALSE;
}
static gboolean do_show_dock()
{
    handle_event(TriggerShow);
    return FALSE;
}

static guint _delay_id = 0;
static void _cancel_delay()
{
    if (_delay_id != 0) {
        g_source_remove(_delay_id);
        _delay_id = 0;
    }
}
void dock_delay_show(int delay)
{
    _cancel_detect_hide_mode();
    if (CURRENT_STATE == StateHidding) {
        do_show_dock();
    } else {
        _cancel_delay();
        _delay_id = g_timeout_add(delay, do_show_dock, NULL);
    }
}
void dock_delay_hide(int delay)
{
    _cancel_detect_hide_mode();
    _cancel_delay();
    _delay_id = g_timeout_add(delay, do_hide_dock, NULL);
}

void dock_show_now()
{
    _cancel_detect_hide_mode();
    handle_event(TriggerShow);
}
void dock_hide_now()
{
    _cancel_detect_hide_mode();
    handle_event(TriggerHide);
}

static guint _detect_hide_mode_id = 0;
static void _cancel_detect_hide_mode()
{
    if (_detect_hide_mode_id != 0) {
        g_source_remove(_detect_hide_mode_id);
        _detect_hide_mode_id = 0;
    }
}
void dock_toggle_show()
{
    if (CURRENT_STATE == StateHidden || CURRENT_STATE == StateHidding) {
        handle_event(TriggerShow);
    } else if (CURRENT_STATE == StateShow || CURRENT_STATE == StateShowing) {
        handle_event(TriggerHide);
    }
    _detect_hide_mode_id = g_timeout_add(3000, (GSourceFunc)dock_update_hide_mode, NULL);
}


GdkWindow* get_dock_guard_window()
{
    static GdkWindow* guard_window = NULL;
    if (guard_window == NULL) {
        GdkWindowAttr attributes;
        attributes.width = _screen_width;
        attributes.height = GUARD_WINDOW_HEIGHT;
        attributes.window_type = GDK_WINDOW_TEMP;
        attributes.wclass = GDK_INPUT_OUTPUT;
        /*attributes.wclass = GDK_INPUT_ONLY;*/
        attributes.event_mask = GDK_ENTER_NOTIFY_MASK;
        /*attributes.event_mask = GDK_ALL_EVENTS_MASK;*/

        guard_window =  gdk_window_new(NULL, &attributes, 0);
        GdkRGBA rgba = { 0, 0, 0, .1 };
        gdk_window_set_background_rgba(guard_window, &rgba);

        gdk_window_show_unraised(guard_window);
    }
    return guard_window;
}
static GdkFilterReturn _monitor_guard_window(GdkXEvent* xevent, 
        GdkEvent* event, gpointer data)
{
    XEvent* xev = xevent;
    XGenericEvent* e = xevent;


    if (xev->type == GenericEvent && e->evtype == EnterNotify) {
        if (GD.config.hide_mode != NO_HIDE_MODE)
            dock_delay_show(50);
    }
    return GDK_FILTER_CONTINUE;
}

void init_dock_guard_window()
{
    GdkWindow* win = get_dock_guard_window();
    gdk_window_add_filter(win, _monitor_guard_window, NULL);
    extern int _screen_height;
    gdk_window_move(win, 0, _screen_height - GUARD_WINDOW_HEIGHT);
}

void dock_update_hide_mode()
{
    if (!GD.is_webview_loaded) return;

    switch (GD.config.hide_mode) {
        case ALWAYS_HIDE_MODE: {
                                   dock_hide_now();
                                   break;
                               }
        case AUTO_HIDE_MODE: {
                                 if (dock_has_overlay_client()) {
                                     dock_delay_hide(50);
                                 } else {
                                     dock_delay_show(50);
                                 }
                                 break;
                             }
        case NO_HIDE_MODE: {
                               dock_show_now();
                               break;
                           }
    }
}