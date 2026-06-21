module status

import frothy7650.chalk
import time
import net

pub fn ssh(url_const string, format bool) !Status {
  mut ok := true

  mut url := url_const

  if !url.contains(':') {
    url += ':22'
  }

  mut conn := net.dial_tcp(url)!
  line := conn.read_line()

  if !line.starts_with('SSH-2.0-OpenSSH_') {
    ok = false
  }

  msg := if ok { 'UP' } else { 'DOWN' }

  conn.close()!

  return Status{
    ok: ok
    msg: '${url} at ${time.now().hhmmss()}: ${if format { chalk.green(msg) } else { msg }}'
    output: line
  }
}
