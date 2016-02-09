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

import std.stdio: File, stdin, write;
import std.getopt: getopt, GetOptException;
import std.outbuffer: OutBuffer;
import core.sys.posix.unistd: isatty;
import lisp;

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
private int main (string[] args) {
	auto env = mkenv();
	auto show_version = false;
	try {		
		try {
			getopt(args, "h|v|?", &show_version);
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