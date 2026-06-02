module main

import net.http
import net

fn get_status(url string, scheme Scheme, script_path string, script_log_path string) !(string, ?string) {
	match scheme {
		.http {
      req := http.get(url)!
      return req.status_code.str(), req.body
    }
		.tcp { return check_port(url, script_path, script_log_path)!, none }
		.mc { return check_mc_server(url)!, none }
	}

	panic('Once again, this should never happen')
}

fn check_port(url_with_scheme string, script_path string, script_log_path string) !string {
	url := url_with_scheme.replace('tcp://', '')
	mut conn := net.dial_tcp(url) or {
		if err.str().contains('code: 111') {
			return 'conn refused'
		}
		return net.error_code().str()
	}

	if script_path != '' {
		run_script(mut conn, script_path, script_log_path)!
		if scriptlogfile.is_opened { scriptlogfile.close() }
	}

	conn.close() or {
		eprintln('Failed to close TCP connection: ${err}')
		exit(8)
	}
	is_conn = false
	return 'online'
}
