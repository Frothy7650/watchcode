module status

pub fn get_status(url string, scheme Scheme, script ?string, format bool, print_script bool) !Status {
  mut status_var := Status{}

  status_var = match scheme {
    .http         { http(url, format)! }
    .tcp          { tcp(url, script, format, print_script)! }
    .mc           { mc(url)! }
  }

  return status_var
}

pub struct Status {
pub:
  ok   bool
  msg  string
  meta map[string]string
  raw  string
}

pub enum Scheme {
	http
	tcp
	mc
}
