import vibe.d;
import std.stdio: File;
import std.file: exists, readText;
import std.outbuffer: OutBuffer;
import std.random;
import std.algorithm.mutation: strip;
import std.array: replace;
import std.regex;
import tinylisp;


void handleRequest(HTTPServerRequest req, HTTPServerResponse res)
{
	res.headers.removeAll("Server");

	auto atom_rx = regex("^[a-z0-9]+$");
	auto path = replaceAll(strip(req.requestURL, '/'), regex("/+", "g"), "/").split("/");
	auto controller = "index";
	if( path.length ) {
		controller = path[0];
		path = path[1..$];
	}

	if( matchAll(controller, atom_rx).empty ) {
		res.statusCode = 400;
		res.writeBody("Invalid Request");
		return;
	}

	auto lisp_file = controller ~ ".lsp";
	if( ! exists(lisp_file) ) {
		res.statusCode = 404;
		res.writeBody("Not Found");
		return;
	}

	auto method_sym = mksym(to!string(req.method));
	auto env = mkenv();

	eval(env, readText(lisp_file));
	auto method = env.mapfind(method_sym).cdr;

	if( method is null ) {
		res.statusCode = 500;
		res.writeBody("Method Not Found");
		return;
	}

	auto result = env.eval(cons(method, symlist(path)));
	res.writeBody(result.sexpr);
}


shared static this()
{
	string[] args;
	finalizeCommandLineOptions(&args);

	auto settings = new HTTPServerSettings;
	settings.port = 7080;
	settings.bindAddresses = ["::1", "127.0.0.1"];

	auto router = new URLRouter;

	router.get("*", &handleRequest);

	listenHTTP(settings, router);
}