//! RedRog: KWin's own blur behind the window, as Dolphin, kitty and the
//! title bar get. KWin 6.8 offers blur through the standard
//! ext-background-effect-v1 Wayland protocol (org_kde_kwin_blur, the only one
//! winit knows, is gone), so this asks for it on the window's own surface.
//! Copied into rog-control-center/src by packages/rog-control-center/redrog-theme.py.

use slint::winit_030::{winit, CustomApplicationHandler, EventResult};
use wayland_client::backend::{Backend, ObjectId};
use wayland_client::globals::{GlobalListContents, registry_queue_init};
use wayland_client::protocol::{wl_compositor::WlCompositor, wl_region::WlRegion, wl_registry::WlRegistry, wl_surface::WlSurface};
use wayland_client::{Connection, Dispatch, Proxy, QueueHandle};
use wayland_protocols::ext::background_effect::v1::client::{
    ext_background_effect_manager_v1::ExtBackgroundEffectManagerV1 as Manager,
    ext_background_effect_surface_v1::ExtBackgroundEffectSurfaceV1 as Effect,
};
use winit::raw_window_handle::{HasDisplayHandle, HasWindowHandle, RawDisplayHandle, RawWindowHandle};

struct State;

impl Dispatch<WlRegistry, GlobalListContents> for State {
    fn event(_: &mut Self, _: &WlRegistry, _: <WlRegistry as Proxy>::Event, _: &GlobalListContents, _: &Connection, _: &QueueHandle<Self>) {}
}

macro_rules! ignore_events {
    ($($t:ty),*) => {$(
        impl Dispatch<$t, ()> for State {
            fn event(_: &mut Self, _: &$t, _: <$t as Proxy>::Event, _: &(), _: &Connection, _: &QueueHandle<Self>) {}
        }
    )*};
}
ignore_events!(WlCompositor, WlRegion, Manager, Effect);

/// Asks KWin to blur behind the whole window (no-op outside Wayland or when
/// the compositor lacks the protocol).
pub fn enable(window: &winit::window::Window) {
    let (Ok(display), Ok(handle)) = (window.display_handle(), window.window_handle()) else {
        return;
    };
    let (RawDisplayHandle::Wayland(display), RawWindowHandle::Wayland(handle)) = (display.as_raw(), handle.as_raw()) else {
        return;
    };
    // one effect per window (a second one on a surface is a protocol error);
    // the window shows again from the tray with the same surface
    static DONE: std::sync::Mutex<Vec<u64>> = std::sync::Mutex::new(Vec::new());
    let key = u64::from(window.id());
    if let Ok(mut done) = DONE.lock() {
        if done.contains(&key) {
            return;
        }
        done.push(key);
    }
    // the window's own Wayland connection, wrapped (not owned)
    let backend = unsafe { Backend::from_foreign_display(display.display.as_ptr().cast()) };
    let conn = Connection::from_backend(backend);
    let Ok((globals, mut queue)) = registry_queue_init::<State>(&conn) else {
        return;
    };
    let qh = queue.handle();
    let (Ok(manager), Ok(compositor)) = (
        globals.bind::<Manager, _, _>(&qh, 1..=1, ()),
        globals.bind::<WlCompositor, _, _>(&qh, 1..=6, ()),
    ) else {
        log::info!("RedRog: no ext-background-effect-v1, no blur");
        return;
    };
    let Ok(id) = (unsafe { ObjectId::from_ptr(WlSurface::interface(), handle.surface.as_ptr().cast()) }) else {
        return;
    };
    let Ok(surface) = WlSurface::from_id(&conn, id) else {
        return;
    };
    let effect = manager.get_background_effect(&surface, &qh, ());
    // the whole surface (the region is clipped to it)
    let region = compositor.create_region(&qh, ());
    region.add(0, 0, 32768, 32768);
    effect.set_blur_region(Some(&region));
    region.destroy();
    // the blur is surface state, applied on commit: commit now instead of
    // waiting for the next frame Slint draws (which can take a second, until
    // something on screen changes), so the window never shows unblurred
    surface.commit();
    let _ = queue.roundtrip(&mut State);
    window.request_redraw();
    // the effect object must live as long as the window
    std::mem::forget(effect);
    std::mem::forget(queue);
}

/// Asks for the blur on the window's first event, before Slint draws its
/// first frame, so the window never shows unblurred
struct EarlyBlur;

impl CustomApplicationHandler for EarlyBlur {
    fn window_event(
        &mut self,
        _: &winit::event_loop::ActiveEventLoop,
        _: winit::window::WindowId,
        winit_window: Option<&winit::window::Window>,
        _: Option<&slint::Window>,
        _: &winit::event::WindowEvent,
    ) -> EventResult {
        if let Some(window) = winit_window {
            enable(window);
        }
        EventResult::Propagate
    }
}

/// Call at the start of main(), before any Slint window exists
pub fn install() {
    let _ = slint::BackendSelector::new()
        .with_winit_custom_application_handler(EarlyBlur)
        .select();
}
