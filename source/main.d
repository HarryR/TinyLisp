/* A minimal Lisp interpreter
   Copyright 2016 Harry Roberts

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License , or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program. If not, write to the Free Software
   Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.
 */

import std.stdio: File, stdin, write, writeln;
import std.getopt: getopt, GetOptException;
import std.outbuffer: OutBuffer;
import std.algorithm: strip, startsWith;
import core.sys.posix.unistd: isatty;
import tinylisp;


private void repl (ref Obj env ) {
	string line;
	while( true ) {
		write("> ");
		if( (line = stdin.readln()) is null ) {
			break;
		}
		write("= ", eval(env, line), "\n");
	}
}


private string readWholeFile (string filename) {
	auto buf = new OutBuffer();
	auto file = File(filename, "rb");
	return readWholeStream(file);
}


private string readWholeStream (File file) {
	auto buf = new OutBuffer();
	if( file.size != ulong.max ) {
		// XXX: this would cause segfault if size unknown
		// e.g. echo '' | ./lisp
		buf.reserve(file.size());
	}
	foreach( chunk; file.byChunk(1024*10) ) {
		buf.write(chunk);
	}
	return buf.toString();
}


/**
 * The testing handle is used to perform automated unit tests
 * It reads a file containing one statement per line
 * The statements are used to create new lisp environments,
 * then to load files into them, execute statements and test outputs
 *
 *  Lines beginning with:
 * 		; - comments
 *  	. - testing / control commands
 *  	> - execute lisp in environment
 *		= - verify result
 *
 *  Control commands:
 *		.reset  - Reset variables
 *		.load   - Load lisp file into environment
 *
 *  Example:
 *		; Test binary functions
 *		.load examples/binary.lsp
 *		> (not 1)
 *		= 0
 */
private void writeError (string filename, uint line_no, string msg) {
	writeln("Error! file: ", filename, " line: ", line_no);
	writeln("     ! ", msg, "\n");
}
private uint testFile (string filename) {
	auto file = File(filename, "rb");
	uint line_no = 0;
	uint error_count = 0;
	auto env = mkenv();
	string last_result;
	string last_stmt;
	foreach( line; file.byLine() ) {
		line_no++;
		line = strip!isWhite(line);
		if( line.length == 0 || line[0] == ';' ) {
			continue;
		}
		// Control statements
		if( line[0] == '.' ) {
			if( startsWith(line, ".load ") ) {
				auto load_filename = strip!isWhite(line[5 .. $]).idup;
				if( ! load_filename.length ) {
					writeError(filename, line_no, "no filename specified for .load");
					continue;
				}
				auto load_data = readWholeFile(load_filename);
				if( load_data !is null && load_data.length ) {
					auto obj = parse(env, load_data);
					if( obj !is null ) {
						eval(env, obj);
					}
				}
			}
			else if ( line == ".reset" ) {
				env = mkenv();
				last_result = null;
			}
			else {
				writeError(filename, line_no, "unknown control command: " ~ line.idup);
				continue;
			}
		}
		else if( line[0] == '>' ) {
			last_stmt = strip!isWhite(line[1 .. $]).idup;
			last_result = eval(env, last_stmt);
		}
		else if( line[0] == '=' ) {
			string expected_result = strip!isWhite(line[1 .. $]).idup;
			if( expected_result != last_result ) {
				error_count++;
				writeError(filename, line_no, "stmt: " ~ last_stmt ~ "\n     ! expected: " ~ expected_result ~ "\n     ! got: " ~ last_result);
				continue;
			}
		}
		else {
			writeError(filename, line_no, "Invalid syntax: " ~ line.idup);
		}
	}
	return error_count;
}


private int main (string[] args) {
	auto env = mkenv();
	auto show_version = false;
	string[] test_files;
	try {
		try {
			getopt(args,
				"h|v|?", &show_version,
				"t|test", &test_files,
			);
		}
		catch ( GetOptException ex ) {
			write("Error: ", ex.msg, "\n");
			show_version = true;
		}
	}
	catch( Exception ex ) {
		show_version = true;
	}
	if( show_version ) {
   		write("Usage: lisp [file ...]\n\n");
   		return 1;
	}

	if( test_files.length ) {
		uint error_count;
		foreach( string filename; test_files ) {
			error_count += testFile(filename);
		}
		return error_count > 0;
	}

	// Silently evaluate any files given on the commandline
	auto files = args[1 .. args.length];
	if( files.length > 0 ) {
		foreach( string filename; files ) {
			string contents;
			try {
				contents = readWholeFile(filename);
			}
			catch( Exception ex ) {
				write("Error: ", ex.msg, "\n");
				return 1;
			}
			if( contents !is null && contents.length ) {
				auto obj = parse(env, contents);
				if( obj !is null ) {
					eval(env, obj);
				}
			}
		}
	}

	// Start a REPL if user is on a terminal
	if( isatty(stdin.fileno()) ) {
		repl(env);
		return 0;
	}
	// Otherwise evaluate the content of stdin
	auto content = readWholeStream(stdin);
	if( content !is null && content.length ) {
		write(eval(env, content), "\n");
	}
	return 0;
}