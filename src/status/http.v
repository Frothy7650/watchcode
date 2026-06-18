module status

import net.http as https
import frothy7650.chalk
import time

pub fn http(url string, format bool) !Status {
	resp := https.get(url)!
	mut meta := map[string]string{}

	// convert headers into meta map
	for key in resp.header.keys() {
		if val := resp.header.get_custom(key, exact: true) {
			meta[key] = val
		}
	}
  meta['body'] = resp.body

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
		ok: ok
		msg: '${url} at ${ts}: ${status_code_and_msg}'
		meta: meta
	}
}
