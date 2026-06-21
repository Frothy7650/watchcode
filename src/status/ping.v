module status

import frothy7650.chalk
import time
import os

pub fn ping(url string, format bool) !Status {
  mut ok := false

  res := os.execute_or_exit('ping -c 1 ${url}')
  output := res.output

  for line in output.split('\n') {
    if line.starts_with('64 bytes from ') {
      ok = true
      break
    }
  }

  msg := if ok { 'UP' } else { 'DOWN' }

  return Status{
    ok: ok
    msg: '${url} at ${time.now().hhmmss()}: ${if format { chalk.green(msg) } else { msg }}'
    output: output
  }
}
