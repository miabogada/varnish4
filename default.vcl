#
# This is an example VCL file for Varnish.
#
# It does not do anything by default, delegating control to the
# builtin VCL. The builtin VCL is called when there is no explicit
# return statement.
#
# See the VCL chapters in the Users Guide at https://www.varnish-cache.org/docs/
# and https://www.varnish-cache.org/trac/wiki/VCLExamples for more examples.

# Marker to tell the VCL compiler that this VCL has been adapted to the
# new 4.0 format.
vcl 4.0;
import std;

# Default backend definition. Set this to point to your content server.
backend default {
    .host = "127.0.0.1";
    .port = "8080";
}

backend tc {
	.host = "127.0.0.1";
	.port = "8081";
}

acl whitelist {
        "127.0.0.1";
        "localhost";
        "66.215.152.158";	#home
	"137.25.6.79";		#lmc office
	"209.210.68.4";		#iolo
}

acl blacklist {
        "195.154.242.0"/24;	#eu comment spam
        "195.154.222.0"/24;	#eu comment spam
        "62.210.0.0"/16;	#eu comment spam	
	"193.106.0.0"/16;	#russia script upload
	"5.188.210.0"/24;	#russia comment spam
}


sub vcl_recv {
    # Happens before we check if we have this in cache already.
    #
    # Typically you clean up the request here, removing cookies you don't need,
    # rewriting the request, etc.

        if (client.ip ~ blacklist) {
                return(synth(403, "Nope."));
        }

#        if (std.ip(regsub(req.http.X-Forwarded-For, ", 70\.132\.16\.89$", ""), "0.0.0.0") ~ blacklist) {
	 if (std.ip(regsub(req.http.X-Forwarded-For, "[, ].*$", ""), "0.0.0.0") ~ blacklist) {
                return(synth(403, "Have a nice day ;)"));
        }

	if (req.http.host ~ "tclarknutrition.com") {
		set req.backend_hint = tc;
	} else {
		set req.backend_hint = default;
	}

	set req.http.cookie = regsuball(req.http.cookie, "wp-settings-\d+=[^;]+(; )?", "");
	set req.http.cookie = regsuball(req.http.cookie, "wp-settings-time-\d+=[^;]+(; )?", "");
	set req.http.cookie = regsuball(req.http.cookie, "wordpress_test_cookie=[^;]+(; )?", "");
	if (req.http.cookie == "") {
		unset req.http.cookie;
	}

//	if (req.method == "PURGE") {
//		if (req.http.X-Purge-Method == "regex") {
//			ban("req.url ~ " + req.url + " &amp;&amp; req.http.host ~ " + req.http.host);
//			return (synth(200, "Banned."));
//		} else {
//			return (purge);
//		}
//	}

	# exclude wordpress url
	if (req.url ~ "wp-admin|wp-login|xmlrpc") {
		if (client.ip ~ whitelist) {
			return (pass);
		} else {
			return (synth(405));
		}
	}

	# protect uploads
	if (req.method == "POST") {
	        if (req.url ~ "wp-admin|wp-login|xmlrpc|uploads") {
		        if (client.ip ~ whitelist) {
			        return (pass);
			} else {
				return (synth(403, "No soup for you."));
			}
		}
	}	

}

sub vcl_backend_response {
    # Happens after we have read the response headers from the backend.
    #
    # Here you clean the response headers, removing silly Set-Cookie headers
    # and other mistakes your backend does.
}

sub vcl_deliver {
    # Happens when we have all the pieces we need, and are about to send the
    # response to the client.
    #
    # You can do accounting or modifying the final object here.
}
