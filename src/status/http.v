module status

import frothy7650.vcookie
import net.http as https
import frothy7650.chalk
import time
import os

pub fn http(url string, format bool, cookies_in_path string, cookies_out_path string) !Status {
	mut request := https.Request{
		method: .get
		url:    url
	}

	if cookies_in_path != '' {
		cookies_in := vcookie.parse(os.read_file(cookies_in_path)!)!
		for cookie in vcookie.to_net_cookies(cookies_in)! {
			request.add_cookie(cookie)
		}
	}

	resp := request.do()!
	mut meta := map[string]string{}

	if cookies_out_path != '' {
		cookies_out := vcookie.from_net_cookies(resp.cookies())!
		cookies_out_raw := vcookie.emit(cookies_out)!
		os.write_file(cookies_out_path, cookies_out_raw)!
	}

	// convert headers into meta map
	for key in resp.header.keys() {
		if val := resp.header.get_custom(key, exact: true) {
			meta[key] = val
		}
	}

	ts := time.now().hhmmss()
	ok := resp.status_code >= 200 && resp.status_code < 400
	status_code_and_msg := if format {
		if ok {
			chalk.green('${resp.status_code} ${resp.status_msg}')
		} else {
			chalk.red('${resp.status_code} ${resp.status_msg}')
		}
	} else {
		'${resp.status_code} ${resp.status_msg}'
	}

	return Status{
		ok:   ok
		msg:  '${url} at ${ts}: ${status_code_and_msg}'
		meta: meta
    output: resp.body
	}
}
