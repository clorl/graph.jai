build :: () {
    set_build_options_dc(.{do_output=false});

    w := compiler_create_workspace();

    opts := get_build_options(w);
		{
				using opts;
				output_executable_name = "main";
				text_output_flags = 0;
				use_ansi_color = false;
		}
    set_build_options(opts, w);
		
		add_build_file("main.jai", w);

		#if OS == .LINUX {
				paths := split(to_string(getenv("LD_LIBRARY_PATH")), ":");
				for paths {
						compiler_add_library_search_directory(it);
				}
		}
}

#run build();

#import "Compiler";
#import "Basic";
#import "String";

#if OS == .LINUX {
    #import "POSIX";
}
