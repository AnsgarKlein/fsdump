/**
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>. 
**/

using GLib;

namespace GLOBALVARIABLES {
	bool debug = true;
	
	int statistics = 0;
	// * 0 none
	// * 1 only
	// * 2 additional
}

static void main(string[] args) {
	string path = "/";
	
	//Parse command line arguments
	for (int i = 0; i< args.length; i++) {
		//stdout.printf("Currently parsing (%d) Argument: %s\n", i, args[i]);
		if (args[i] == "-d" || args[i] == "--directory") {
			if ((i+1) == args.length) {
				stderr.printf("Error!\n");
				stderr.printf("Please specify a directory path!\n\n\n");
				print_help();
				return;
			}
			else {
				path = args[i+1];
			}
		}
		else if (args[i] == "-h" || args[i] == "--help") {
			print_help();
			return;
		}
		else if (args[i] == "-q" || args[i] == "--quiet") {
			//don't print errors (stderr), but print normal output (stdout)
			GLOBALVARIABLES.debug = false;
			
			//just to be sure ...
			//actually not sure if this is a good idea
			stderr = GLib.FileStream.open("/dev/null", "w");
		}
		else if (args[i] == "-s" || args[i] == "--statistics") {
			if ((i+1) == args.length) {
				stderr.printf("Error!\n");
				stderr.printf("Please specify a value for statistics option!\n");
				stderr.printf("Possible values are: none, only, additional\n\n\n");
				print_help();
				return;
			}
			else {
				switch (args[i+1]) {
					default:
						stderr.printf("Error!\n");
						stderr.printf("Please specify a value for statistics option!\n");
						stderr.printf("Possible values are: none, only, additional\n\n\n");
						print_help();
						return;
					case "none":
						GLOBALVARIABLES.statistics = 0;
						break;
					case "only":
						GLOBALVARIABLES.statistics = 1;
						break;
					case "additional":
						GLOBALVARIABLES.statistics = 2;
						break;
				}
			}
		}

	}
	
	//Start Execution
	int dirCount = 0;
	int fileCount = 0;
	
	switch (GLOBALVARIABLES.statistics) {
		case 0:
			stdout.printf(scan_directory(path, ref dirCount, ref fileCount));
			break;
		case 1:
			scan_directory(path, ref dirCount, ref fileCount);
			stdout.printf("Files: %d\n", fileCount);
			stdout.printf("Directories: %d\n", dirCount);
			break;
		case 2:
			stdout.printf(scan_directory(path, ref dirCount, ref fileCount));
			stdout.printf("\n");
			stdout.printf("Files: %d\n", fileCount);
			stdout.printf("Directories: %d\n", dirCount);
			break;
		default:
			stderr.printf("\n\n\nTHERE IS SOMETHING SERIOUSLY WRONG !\n\n\n");
			return;
	}
}

static void print_help() {
	stdout.printf("""This program will scan a filesystem hierarchy and print it in a machine-readable format.

All files will be listed in one line seperated by commas (commas in filenames will be escaped). Directories will be displayed as foldername with their contents in brackets after them. (brackets in filenames will be escaped)
For example:
topfolder1(file1,file2,subfolder(sub1,sub2),file3),topfolder2(folder())

Though this program does not support writing its output to a file it is perfectly safe to redirect all its output (stdout, not stderr) to a file.
On most systems you can do this by adding:
> filename_to_write_output
after the program command.""");
	
	stdout.printf("\n\nOptions:\n");
	
	stdout.printf("  -d, --directory\tThe directory to start scanning at, fsdump will\n");
	stdout.printf("  \t\t\tcontinue to scan directories recursively.\n");
	stdout.printf("  \t\t\tIf you don't have the required rights to read a\n");
	stdout.printf("  \t\t\tdirectory, fsdump will print an error and go on.\n");
	stdout.printf("  \t\t\tIf -d is not given fsdump will assume / as a path.\n");
	
	stdout.printf("  -h, --help\t\tPrint this help and exit\n");
	stdout.printf("  \t\t\tNote: this will not be influenced by -q\n");
	
	stdout.printf("  -q, --quiet\t\tDon't print errors (for example if a directory could\n");
	stdout.printf("  \t\t\tnot be searched because you do not have the required\n");
	stdout.printf("  \t\t\trights)\n");
	stdout.printf("  \t\t\tBut of course this will still print normal file\n");
	stdout.printf("  \t\t\tsystem hierarchy.\n");
	stdout.printf("  \t\t\tDefault is to print errors (to stderr).\n");
	stdout.printf("  \t\t\tNote: This will not influence -h / --help\n");
	
	stdout.printf("  -s, --statistics\tWhether (and how) to print statistics.\n");
	stdout.printf("  \t\t\tTheses statistics consist of:\n");
	stdout.printf("  \t\t\t- Number of files\n");
	stdout.printf("  \t\t\t- Number of directories\n");
	stdout.printf("  \t\t\tInternally these statistics get created anyway so there\n");
	stdout.printf("  \t\t\tshould be no speed difference.\n");
	stdout.printf("  \t\t\tPossible values:\n");
	stdout.printf("  \t\t\t- none [DEFAULT]\n");
	stdout.printf("  \t\t\t  Don't print statistics. (only filesystem hierarchy)\n");
	stdout.printf("  \t\t\t- only\n");
	stdout.printf("  \t\t\t  Print only statistics and no filesystem hierarchy.\n");
	stdout.printf("  \t\t\t- additional\n");
	stdout.printf("  \t\t\t  Print filesystem hierarchy and on line two and three\n");
	stdout.printf("  \t\t\tprint statistics. (This might not be easy to parse...)\n");
}

static string escape(string str) {
	str.replace(",", "\\,");
	str.replace(")", "\\)");
	str.replace("(", "\\(");
	return str;
}

static string scan_directory(string path, ref int dirCount, ref int fileCount) {
	bool put_comma = false;
	StringBuilder str_bld = new StringBuilder();
	
	GLib.File directory = GLib.File.new_for_path(path);
	
	try {
		GLib.FileEnumerator enumerator = directory.enumerate_children(FileAttribute.STANDARD_NAME+","+FileAttribute.STANDARD_EDIT_NAME+","+FileAttribute.STANDARD_DISPLAY_NAME, GLib.FileQueryInfoFlags.NONE);
		GLib.FileInfo file_info;
		//Enumerate over all subfiles (directories and files)
		while ((file_info = enumerator.next_file()) != null) {
			
			//If the current subfile is a file
			if (file_info.get_file_type() == GLib.FileType.REGULAR) {
				//Add a comma if necessary to seperate files from another
				if (put_comma) {
					str_bld.append_c(',');
				} else {
					put_comma = true;
				}
				
				//Add file name
				str_bld.append(escape(file_info.get_name()));
				fileCount++;
			}
			
			//If the current subfile is a directory
			else if (file_info.get_file_type() == GLib.FileType.DIRECTORY) {
				//Add a comma if necessary to seperate files from another
				if (put_comma) {
					str_bld.append_c(',');
				} else {
					put_comma = true;
				}
				
				//Add directory name
				str_bld.append(escape(file_info.get_name()));
				
				//List all subfiles recursively inside braces
				str_bld.append_c('(');
				if (path.get_char(path.length-1) != '/') {
					str_bld.append(escape(scan_directory(path+"/"+file_info.get_name(), ref dirCount, ref fileCount)));
				} else {
					str_bld.append(escape(scan_directory(path+file_info.get_name(), ref dirCount, ref fileCount)));
				}
				
				str_bld.append_c(')');
				dirCount++;
			}
		}
		enumerator.close();
	}
	catch (GLib.Error e) {
		if (GLOBALVARIABLES.debug) {
			stderr.printf("\nError while iterating over directorys\n");
			stderr.printf("Path: %s\n", path);
			stderr.printf("Error: %s\n", e.message);
		}
	}
	
	return str_bld.str;			
}
