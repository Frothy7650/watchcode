module status

import frothy7650.chalk
import time
import net

fn tcp(url string, script ?string, format bool, print_script bool) !Status {
	mut conn := net.dial_tcp(url) or {
		if err.str().contains('code: 111') {
      return Status{
        ok: false
        msg: '${url} at ${time.now().hhmmss()}: ${if format { chalk.red('connection refused') } else { 'connection refused' }}'
      }
		}
    return Status{
      ok: false
      msg: '${url} at ${time.now().hhmmss()}: ${if format { chalk.red(err.msg()) } else { err.msg() }}'
    }
	}

  lines := if script != none { run_script(mut conn, script, print_script)! } else { '' }

	conn.close() or {
		eprintln('Failed to close TCP connection: ${err}')
		exit(8)
	}

  mut meta := map[string]string{}
  meta['script_lines'] = lines

	return Status{
    ok: true
    msg: '${url} at ${time.now().hhmmss()}: ${if format { chalk.green('UP') } else { 'UP' }}'
    meta: meta
  }
}
