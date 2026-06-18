#load "ui.jai";
#load "draw.jai";
#load "graph.jai";

loop :: () -> bool {

		// --- INPUT
		for Input.events_this_frame {
				using it;
				if type == .QUIT || type == .KEYBOARD && key_pressed && key_code == .ESCAPE
				then return true;

				Gui.getrect_handle_event(it);

				if type == {
						// case .DRAG_AND_DROP_FILES;
						// for dropped_files free(it);
						// array_reset(*dropped_files);
						// for event.files array_add(*dropped_files, copy_string(it));
				}
		}

		// --- LOGIC


		// --- RENDERING
		{
				using Simp;
				set_shader_for_color();
				{ using Colors.background; clear_render_target(x, y, z, w); }

				new_ctx := context; push_context new_ctx {
						context.transform.basis = .{100, 0, 0,  -100};
						context.transform.origin = .{ Graphics_Settings.win_width / 2.0, Graphics_Settings.win_height / 2.0 };

						draw_grid(Transform2D.{}, Colors.foreground * .5, 1);
						draw_grid(Transform2D.{
								basis = { .5, 0,
									0, .5
								}
						}, Colors.foreground * .34, .5);
						draw_grid(scale(Transform2D.{}, 4), Colors.foreground * .8, 1);
						draw_arrow(.{0, 0}, .{1, 0}, Colors.red);
						draw_arrow(.{0, 0}, .{0, 1}, Colors.green);

						render_graph(*graph);
				}

				immediate_flush();
		}

		// --- UI
		draw_ui();

		Simp.swap_buffers(window);

		return false;
}

graph_init :: (neighbors := 3) {
		graph = create_graph(3);
		graph_apply_physics(*graph, 100);
}

// Initializes the window and stuff after creation
init :: (first_init := false) {
		if first_init {
				Gui.ui_init();
				graph_init();
		}


		{ // --- LOAD FONTS
				size := Graphics_Settings.win_height / 24;
				inter_tight := Simp.get_font_at_size("fonts/Inter_Tight/static", "InterTight-Medium.ttf", size);
				jetbrains_mono := Simp.get_font_at_size("fonts/JetBrains_Mono", "JetBrainsMono-VariableFont_wght.ttf", size);

				Fonts.mono = jetbrains_mono;
				Fonts.sans = inter_tight;
				Fonts.default = Fonts.sans;
		}
}

main :: () {
		frame_last_time := seconds_since_init();
		#if OS == .WINDOWS {
				Windows :: #import "Windows";
				Windows.SetProcessDPIAware();
				Windows.timeBeginPeriod(1);
		}

		{
				using Graphics_Settings;
				window = create_window(win_width, win_height, WINDOW_TITLE, wanted_msaa = wanted_msaa);
				msaa = Simp.prepare_window(window, wanted_msaa = wanted_msaa);
				win_width, win_height = Simp.get_render_dimensions(window);
		}

		// Support for drag and drop
		#if OS == .WINDOWS {
				Windows.DragAcceptFiles(window, cast(Windows.BOOL) true);
		} else #if OS == .LINUX {
				X11 :: #import "X11";
				typelist := string.["url/url", "text/uri-list", "text/plain", "application/octet-stream"];
				X11.enable_drag_and_drop(window, typelist);
		} else #if OS == .MACOS {
				assert(false, "MacOS is not supported");
		}

		Simp.set_render_target(window, .LEFT_HANDED);
		init(true);

		should_quit := false;
		while !should_quit {
				context.frame_start_time = xx seconds_since_init();
				context.frame += 1;
				context.delta_time = cast(float)(context.frame_start_time - frame_last_time);
				frame_last_time = context.frame_start_time;
				Input.update_window_events();

				#if OS == .WINDOWS {
						if Input.window_minimized continue; //@Todo Handle this more gracefully, right now it just gives a big delta time when unminimized which could cause problems
				}

				for Input.get_window_resizes() {
						Simp.update_window(it.window);
						if it.window == window {
								using Graphics_Settings;
								should_reinit := (it.width != win_width) || (it.height != win_height);
								win_width = it.width;
								win_height = it.height;

								if should_reinit init();
						}
				}

				x, y, width, height := get_dimensions(window, true);
				Gui.ui_per_frame_update(window, width, height, seconds_since_init());
				should_quit = loop();
				reset_temporary_storage();
		}
}

Graphics_Settings : struct {
		win_width := 1280;
		win_height := 720;
		wanted_msaa: s32 = 8;
		msaa := 8;
		limit_fps := false;
		target_fps := 60;
		target_dt := 1.0/60; //@Cleanup
}

Colors : struct {
		background	:= Vector4.{0.09, 0.09, 0.15, 1};
		foreground	:= Vector4.{0.8, 0.84, 0.96, 1};
		red				:= Vector4.{0.95, 0.55, 0.66, 1};
		blue			:= Vector4.{0.54, 0.71, 0.98, 1};
		green			:= Vector4.{0.65, 0.89, 0.63, 1};
		white        := Vector4.{1, 1, 1, 1};
}

Fonts : struct {
		default: *Simp.Dynamic_Font;
		mono: *Simp.Dynamic_Font;
		sans: *Simp.Dynamic_Font;
}

window: Window_Type;

#add_context frame: int = 0;
#add_context frame_start_time: float;
#add_context delta_time: float = 0.0;
#add_context start_time: Apollo_Time;
#add_context time_scale: float = .2;

WINDOW_TITLE :: "App FORCE_FLOAT";

#import "Basic";
#import "Window_Creation";
Input :: #import "Input";
Simp :: #import "Simp";
Gui :: #import "GetRect_LeftHanded";
#import "Math";
