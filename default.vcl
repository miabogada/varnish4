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
	"73.24.6.28";		#joey apt
	"73.242.37.242";	#stpaul temp
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
                if (req.http.host ~ "^tclarknutrition.com") {
                        return (synth (750));
                }
	} else {
		set req.backend_hint = default;
	        if (req.http.host ~ "^miabogada.com") {
			return (synth (750));
		}
	}


    # Mark static files with the X-Static-File header, and remove any cookies
    # X-Static-File is also used in vcl_backend_response to identify static files
    if (req.url ~ "^[^?]*\.(7z|avi|bmp|bz2|css|csv|doc|docx|eot|flac|flv|gif|gz|ico|jpeg|jpg|js|less|mka|mkv|mov|mp3|mp4|mpeg|mpg|odt|ogg|ogm|opus|otf|pdf|png|ppt|pptx|rar|rtf|svg|svgz|swf|tar|tbz|tgz|ttf|txt|txz|wav|webm|webp|woff|woff2|xls|xlsx|xml|xz|zip)(\?.*)?$") {
        set req.http.X-Static-File = "true";
        unset req.http.Cookie;
        return(hash);
    }


    # No caching of special URLs, logged in users and some plugins
    if (
        req.http.Cookie ~ "wordpress_(?!test_)[a-zA-Z0-9_]+|wp-postpass|comment_author_[a-zA-Z0-9_]+|woocommerce_cart_hash|woocommerce_items_in_cart|wp_woocommerce_session_[a-zA-Z0-9]+|wordpress_logged_in_|comment_author|PHPSESSID" ||
        req.http.Authorization ||
        req.url ~ "add_to_cart" ||
        req.url ~ "edd_action" ||
        req.url ~ "nocache" ||
        req.url ~ "^/addons" ||
        req.url ~ "^/bb-admin" ||
        req.url ~ "^/bb-login.php" ||
        req.url ~ "^/bb-reset-password.php" ||
        req.url ~ "^/cart" ||
        req.url ~ "^/checkout" ||
        req.url ~ "^/control.php" ||
        req.url ~ "^/login" ||
        req.url ~ "^/logout" ||
        req.url ~ "^/lost-password" ||
        req.url ~ "^/my-account" ||
        req.url ~ "^/product" ||
        req.url ~ "^/register" ||
        req.url ~ "^/register.php" ||
        req.url ~ "^/server-status" ||
        req.url ~ "^/signin" ||
        req.url ~ "^/signup" ||
        req.url ~ "^/stats" ||
        req.url ~ "^/wc-api" ||
        req.url ~ "^/wp-admin" ||
        req.url ~ "^/wp-comments-post.php" ||
        req.url ~ "^/wp-cron.php" ||
        req.url ~ "^/wp-login.php" ||
        req.url ~ "^/wp-activate.php" ||
        req.url ~ "^/wp-mail.php" ||
        req.url ~ "^/wp-login.php" ||
        req.url ~ "^\?add-to-cart=" ||
        req.url ~ "^\?wc-api=" ||
        req.url ~ "^/preview=" ||
        req.url ~ "^/\.well-known/acme-challenge/"
    ) {
	     set req.http.X-Cacheable = "NO:Logged in/Got Sessions";
	     if(req.http.X-Requested-With == "XMLHttpRequest") {
		     set req.http.X-Cacheable = "NO:Ajax";
	     }
        return(pass);
    }


    if (req.http.Cookie) {
    set req.http.Cookie = ";" + req.http.Cookie;
    set req.http.Cookie = regsuball(req.http.Cookie, "; +", ";");
    set req.http.Cookie = regsuball(req.http.Cookie, ";(wordpress_logged_in_[A-Za-z0-9]+)=", "; \1=");
    set req.http.Cookie = regsuball(req.http.Cookie, ";[^ ][^;]*", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "^[; ]+|[; ]+$", "");
    
    if (req.http.Cookie ~ "^\s*$") {
        unset req.http.cookie;
	}
    }

//	set req.http.cookie = regsuball(req.http.cookie, "wp-settings-\d+=[^;]+(; )?", "");
//	set req.http.cookie = regsuball(req.http.cookie, "wp-settings-time-\d+=[^;]+(; )?", "");
//	set req.http.cookie = regsuball(req.http.cookie, "wordpress_test_cookie=[^;]+(; )?", "");
//	if (req.http.cookie == "") {
//		unset req.http.cookie;
//	}

//	if (req.method == "PURGE") {
//		if (req.http.X-Purge-Method == "regex") {
//			ban("req.url ~ " + req.url + " &amp;&amp; req.http.host ~ " + req.http.host);
//			return (synth(200, "Banned."));
//		} else {
//			return (purge);
//		}
//	}

	# exclude wordpress url
	if (req.url ~ "wp-admin|wp-login|xmlrpc|wp-db|\.git$") {
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

sub vcl_synth {
    if (resp.status == 750) {
        set resp.status = 301;
        set resp.http.Location = "https://www." +req.http.host + req.url;
	set resp.reason = "Moved";
        return(deliver);
    }
}
