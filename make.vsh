#!/usr/bin/env -S v run

import build

const app_name = 'bin/watchcode'

mut context := build.context(
	default: 'build'
)

context.task(
	name:    'build'
	depends: ['get_githash']
	run:     |self| system('v -enable-globals src/. -o ${app_name}')
)

context.task(
	name:    'build-prod'
	depends: ['get_githash']
	run:     |self| system('v -cc clang -prod -enable-globals src/. -o ${app_name}')
)

context.task(
	name: 'format'
	run:  |self| system('v fmt -w src/*.v')
)

context.task(
	name:    'setup'
	depends: ['get_githash', 'build-prod']
	run:     |self| cp(app_name, join_path(local_bin_dir(), 'watchcode'))!
)

context.task(
	name: 'get_githash'
	run:  |self| system('git log -n 1 --pretty=format:"%h" > .githash')
)

context.run()
